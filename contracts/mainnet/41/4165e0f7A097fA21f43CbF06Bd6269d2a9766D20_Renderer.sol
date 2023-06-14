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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
interface IERC165 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

// SPDX-License-Identifier: MIT
// Thanks Yos Riady
// Refer to https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/OwnableUpgradeable.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract SafeOwnableUpgradeable is Initializable, ContextUpgradeable {
    error CallerNotOwner();
    error ZeroAddressOwnerSet();
    error CallerNotPendingOwner();
    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address owner_) internal onlyInitializing {
        __Ownable_init_unchained(owner_);
    }

    function __Ownable_init_unchained(
        address owner_
    ) internal onlyInitializing {
        _transferOwnership(owner_);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Return the address of the pending owner
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner() != _msgSender()) {
            revert CallerNotOwner();
        }
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * Note If direct is false, it will set an pending owner and the OwnerShipTransferring
     * only happens when the pending owner claim the ownership
     */
    function transferOwnership(
        address newOwner,
        bool direct
    ) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddressOwnerSet();
        }
        if (direct) {
            _transferOwnership(newOwner);
        } else {
            _transferPendingOwnership(newOwner);
        }
    }

    /**
     * @dev pending owner call this function to claim ownership
     */
    function claimOwnership() public {
        if (msg.sender != _pendingOwner) {
            revert CallerNotPendingOwner();
        }

        _claimOwnership();
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        // compatible with hardhat-deploy, maybe removed later
        assembly {
            sstore(_ADMIN_SLOT, newOwner)
        }

        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev set the pending owner address
     * Internal function without access restriction.
     */
    function _transferPendingOwnership(address newOwner) internal virtual {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _claimOwnership() internal virtual {
        address oldOwner = _owner;
        emit OwnershipTransferred(oldOwner, _pendingOwner);

        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IAirdropVault} from "src/interfaces/IAirdropVault.sol";

contract AirdropVault is IAirdropVault, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    address public immutable rebornToken;

    /**
     * @dev receive native token
     */
    receive() external payable {}

    constructor(address owner_, address rebornToken_) {
        if (rebornToken_ == address(0)) revert ZeroAddressSet();
        _transferOwnership(owner_);
        rebornToken = rebornToken_;
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function rewardDegen(
        address to,
        uint256 amount
    ) external virtual override onlyOwner {
        IERC20(rebornToken).safeTransfer(to, amount);
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function rewardNative(
        address to,
        uint256 amount
    ) external virtual override nonReentrant onlyOwner {
        payable(to).sendValue(amount);
    }

    /**
     * @notice withdraw token Emergency
     */
    function withdrawEmergency(address to) external virtual override onlyOwner {
        if (to == address(0)) revert ZeroAddressSet();
        uint256 degenBalance = IERC20(rebornToken).balanceOf(address(this));
        uint256 nativeBalance = address(this).balance;
        IERC20(rebornToken).safeTransfer(to, degenBalance);

        payable(to).sendValue(nativeBalance);

        emit WithdrawEmergency(to, rebornToken, degenBalance, nativeBalance);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IAirdropVaultDef {
    error ZeroAddressSet();

    event WithdrawEmergency(
        address indexed to,
        address degenToken,
        uint256 degenAmount,
        uint256 nativeAmount
    );
}

interface IAirdropVault is IAirdropVaultDef {
    function rewardDegen(address to, uint256 amount) external; // send degen reward

    function rewardNative(address to, uint256 amount) external; // send native reward

    function withdrawEmergency(address to) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {PortalLib} from "src/PortalLib.sol";
import {BitMapsUpgradeable} from "src/oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

interface IRebornDefinition {
    struct InnateParams {
        uint256 talentNativePrice;
        uint256 talentDegenPrice;
        uint256 propertyNativePrice;
        uint256 propertyDegenPrice;
    }

    struct ReferParams {
        address parent;
        address grandParent;
    }

    struct SoupParams {
        uint256 soupPrice;
        uint256 charTokenId;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct ExhumeParams {
        address exhumee;
        uint256 tokenId;
        uint256 nativeCost;
        uint256 degenCost;
        uint256 shovelTokenId; // if no shovel, tokenId is 0
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct PermitParams {
        uint256 amount;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct LifeDetail {
        bytes32 seed;
        address creator; // ---
        // uint96 max 7*10^28  7*10^10 eth  //   |
        uint96 reward; // ---
        uint96 rebornCost; // ---
        uint16 age; //   |
        uint32 round; //   |
        // uint64 max 1.8*10^19             //   |
        uint64 score; //   |
        uint48 nativeCost; // only with decimal of 10^6 // ---
        string creatorName;
    }

    struct SeasonData {
        mapping(uint256 => PortalLib.Pool) pools;
        /// @dev user address => pool tokenId => Portfolio
        mapping(address => mapping(uint256 => PortalLib.Portfolio)) portfolios;
        uint256 _placeholder;
        uint256 _placeholder2;
        uint256 _placeholder3;
        uint256 _placeholder4;
        uint256 _placeholder5;
        uint256 _jackpot;
    }

    struct AirDropDebt {
        uint128 nativeDebt;
        uint128 degenDebt;
    }

    struct ClaimRewardParams {
        address user;
        uint256 amount;
        uint256 t;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    event AirdropNative();
    event AirdropDegen();

    event Exhume(
        address indexed exhumer,
        address exhumee,
        uint256 indexed tokenId,
        uint256 indexed shovelTokenId,
        uint256 nonce,
        uint256 nativeCost,
        uint256 degenCost,
        uint256 nativeToJackpot
    );

    enum AirdropVrfType {
        Invalid,
        DropReborn,
        DropNative
    }

    enum TributeDirection {
        Reverse,
        Forward
    }

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        bool executed; // whether the airdrop is executed
        AirdropVrfType t;
        uint256 randomWords; // we only need one random word. keccak256 to generate more
    }

    struct VrfConf {
        bytes32 keyHash;
        uint64 s_subscriptionId;
        uint32 callbackGasLimit;
        uint32 numWords;
        uint16 requestConfirmations;
    }

    struct AirdropConf {
        bool _dropOn; //                  ---
        bool _lockRequestDropReborn;
        bool _lockRequestDropNative;
        uint24 _rebornDropInterval; //        |
        uint24 _nativeDropInterval; //        |
        uint32 _rebornDropLastUpdate; //      |
        uint32 _nativeDropLastUpdate; //      |
        uint120 _placeholder;
    }

    struct EngraveParams {
        uint256 tokenId;
        bytes32 seed;
        uint256 reward;
        uint256 score;
        uint256 age;
        uint256 nativeCost;
        uint256 rebornCost;
        uint256 shovelAmount;
        uint256 charTokenId;
        uint256 recoveredAP;
        string creatorName;
    }

    // define degen reward is odd, native reward is even
    enum RewardToClaimType {
        Invalid,
        EngraveDegen, // 1
        ReferNative, // 2
        ReferDegen // 3
    }

    struct RewardStore {
        uint256 totalReward;
        uint256 rewardDebt;
    }

    event ClaimReward(
        address indexed user,
        RewardToClaimType indexed t,
        uint256 amount
    );

    event ClaimDegenReward(
        address indexed user,
        uint256 indexed nonce,
        uint256 amount,
        uint256 t,
        bytes32 r,
        bytes32 s,
        uint8 v
    );

    event Refer(address referee, address referrer);

    event Incarnate(
        address indexed user,
        uint256 indexed tokenId,
        uint256 indexed charTokenId,
        uint256 talentNativePrice,
        uint256 talentRebornPrice,
        uint256 propertyNativePrice,
        uint256 propertyRebornPrice,
        uint256 soupPrice
    );

    event Engrave(
        bytes32 indexed seed,
        address indexed user,
        uint256 indexed tokenId,
        uint256 score,
        uint256 reward,
        uint256 shovelAmount,
        uint256 startTokenId,
        uint256 charTokenId,
        uint256 recoveredAP
    );

    event Infuse(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    );

    event Baptise(
        address indexed user,
        uint256 amount,
        uint256 indexed baptiseType
    );

    event NewSoupPrice(uint256 price);

    event SwitchPool(
        address indexed user,
        uint256 indexed fromTokenId,
        uint256 indexed toTokenId,
        uint256 fromAmount,
        uint256 reStakeAmount,
        TributeDirection fromDirection,
        TributeDirection toDirection
    );

    /// @dev event about the vault address is set
    event VaultSet(address rewardVault);

    event AirdropVaultSet(address airdropVault);

    event NewSeason(uint256 newSeason);

    event NewIncarnationLimit(uint256 limit);

    event ForgedTo(
        uint256 indexed tokenId,
        uint256 newLevel,
        uint256 burnTokenAmount
    );

    event SetNewPiggyBankFee(uint256 piggyBankFee);

    event ClaimNativeAirdrop(uint256 amount);
    event ClaimDegenAirdrop(uint256 amount);

    event NativeDropRootSet(bytes32, uint256);
    event DegenDropRootSet(bytes32, uint256);

    /// @dev revert when the random seed is duplicated
    error SameSeed();

    /// @dev revert when incarnation count exceed limit
    error IncarnationExceedLimit();

    error InvalidProof();

    error NoRemainingReward();

    error SeasonAlreadyStopped();
}

interface IRebornPortal is IRebornDefinition {
    /**
     * @dev user buy the innate for the life
     * @param innate talent and property choice
     * @param referParams refer params
     */
    function incarnate(
        InnateParams calldata innate,
        ReferParams calldata referParams,
        SoupParams calldata charParams
    ) external payable;

    function incarnate(
        InnateParams calldata innate,
        ReferParams calldata referParams,
        SoupParams calldata charParams,
        PermitParams calldata permitParams
    ) external payable;

    function engrave(EngraveParams calldata engraveParams) external;

    /**
     * @dev reward for share the game
     * @param user user address
     * @param amount amount for reward
     */
    function baptise(
        address user,
        uint256 amount,
        uint256 baptiseType
    ) external;

    /**
     * @dev stake $REBORN on this tombstone
     * @param tokenId tokenId of the life to stake
     * @param amount stake amount, decimal 10^18
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) external;

    /**
     * @dev stake $REBORN with permit
     * @param tokenId tokenId of the life to stake
     * @param amount amount of $REBORN to stake
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection,
        PermitParams calldata permitParams
    ) external;

    function switchPool(
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount,
        TributeDirection fromDirection,
        TributeDirection toDirection
    ) external;

    function claimNativeDrops(
        uint256 totalAmount,
        bytes32[] calldata proof
    ) external;

    function claimDegenDrops(
        uint256 totalAmount,
        bytes32[] calldata proof
    ) external;

    /**
     * @dev switch to next season, call by owner
     */
    function toNextSeason() external;

    /**
     * @dev claim reward set by merkle tree
     */
    function claimReward(RewardToClaimType t) external;

    /**
     * @dev claim $DEGEN reward via signer signature
     */
    function claimDegenReward(
        ClaimRewardParams calldata claimRewardParams
    ) external;

    /**
     * @dev get current nonce for claim $DEGEN reward via signature
     */
    function getClaimDegenNonces(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IRegistry {
    event SignerUpdate(address signer, bool valid);

    function checkIsSigner(address addr) external view returns (bool);

    function getDegen() external view returns (address);

    function getPortal() external view returns (address);

    function getShovel() external view returns (address);

    function getPiggyBank() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IRewardVault {
    error ZeroAddressSet();
    
    function reward(address to, uint256 amount) external; // send reward

    function withdrawEmergency(address to) external;

    event WithdrawEmergency(address p12Token, uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

library CommonError {
    error ZeroAddressSet();
    error InvalidParams();
    /// @dev revert when to caller is not signer
    error NotSigner();
    error NotPortal();
    error ExhumeeNotTombStoneOwner();
    error NotShovelOwner();
    error TombstoneNotEngraved();
    error SignatureExpired();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";

library RenderConstant {
    string internal constant _P1 =
        '<svg width="1244" height="704" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><path d="M2.5 701.5V95.051L97.02 2.5H1241.5v699H2.5z" fill="url(#prefix__p0)" stroke="url(#prefix__p1)" stroke-width="5"/><path d="M1240 10H86.11v2.346H1240V10zM76.727 19.384H1240v2.346H76.727v-2.346zM4 169.529h1236v2.346H4v-2.346zM1240 56.92H39.19v2.346H1240V56.92zM4 207.066h1236v2.346H4v-2.346zM1240 94.457H4v2.346h1236v-2.346zM4 329.059h1236v2.346H4v-2.346zM1240 244.602H4v2.346h1236v-2.346zM4 131.993h1236v2.346H4v-2.346zM1240 282.138H4v2.346h1236v-2.346zM57.959 38.152H1240v2.346H57.959v-2.346zM1240 188.298H4v2.346h1236v-2.346zM20.422 75.689H1240v2.346H20.422v-2.346zM1240 310.291H4v2.346h1236v-2.346zM4 225.834h1236v2.346H4v-2.346zM1240 113.225H4v2.346h1236v-2.346zM4 263.37h1236v2.346H4v-2.346zM1240 150.761H4v2.346h1236v-2.346zM4 300.907h1236v2.346H4v-2.346zM4 160.145h1236v2.346H4v-2.346zM1240 47.536H48.574v2.346H1240v-2.346zM4 197.682h1236v2.346H4v-2.346zM1240 85.073H11.038v2.346H1240v-2.346zM4 319.675h1236v2.346H4v-2.346zM1240 235.218H4v2.346h1236v-2.346zM4 122.609h1236v2.346H4v-2.346zM1240 272.754H4v2.346h1236v-2.346zM67.343 28.768H1240v2.346H67.343v-2.346zM1240 178.913H4v2.347h1236v-2.347zM29.806 66.305H1240v2.345H29.806v-2.346zM1240 216.45H4v2.346h1236v-2.346zM4 103.841h1236v2.346H4v-2.346zM1240 338.443H4v2.346h1236v-2.346zM4 253.986h1236v2.346H4v-2.346zM1240 141.377H4v2.346h1236v-2.346zM4 291.522h1236v2.346H4v-2.346zM4 347.827h1236v2.346H4v-2.346zM1240 357.211H4v2.346h1236v-2.346zM1240 507.356H4v2.346h1236v-2.346zM4 394.747h1236v2.346H4v-2.346zM1240 544.893H4v2.346h1236v-2.346zM4 432.284h1236v2.346H4v-2.346zM1240 666.886H4v2.346h1236v-2.346zM4 582.429h1236v2.346H4v-2.346zM1240 469.82H4v2.346h1236v-2.346zM4 619.965h1236v2.346H4v-2.346zM1240 375.979H4v2.346h1236v-2.346zM4 526.125h1236v2.346H4v-2.346zM1240 413.516H4v2.346h1236v-2.346zM4 648.118h1236v2.346H4v-2.346zM1240 563.661H4v2.346h1236v-2.346zM4 451.052h1236v2.346H4v-2.346zM1240 601.197H4v2.346h1236v-2.346zM4 488.588h1236v2.346H4v-2.346zM1240 638.734H4v2.346h1236v-2.346zM1240 497.972H4v2.346h1236v-2.346zM4 385.363h1236v2.346H4v-2.346zM1240 535.509H4v2.346h1236v-2.346zM4 422.9h1236v2.346H4V422.9zM1240 657.502H4v2.346h1236v-2.346zM4 573.045h1236v2.346H4v-2.346zM1240 460.436H4v2.346h1236v-2.346zM4 610.581h1236v2.346H4v-2.346zM1240 366.595H4v2.346h1236v-2.346zM4 516.74h1236v2.346H4v-2.346zM1240 404.131H4v2.347h1236v-2.347zM4 554.277h1236v2.346H4v-2.346zM1240 441.668H4v2.346h1236v-2.346zM4 676.27h1236v2.346H4v-2.346zM1240 685.654H4V688h1236v-2.346zM4 591.813h1236v2.346H4v-2.346zM1240 479.204H4v2.346h1236v-2.346zM4 629.349h1236v2.346H4v-2.346z" fill="url(#prefix__p2)"/><path d="M1244 12V0H96L0 94v18L102 12h1142z" fill="#F98701"/><text dx="76" dy="605" dominant-baseline="central" style="height:100px" font-family="VT323" textLength="1075" font-size="60" fill="#FF8A01">Seed: ';
    string internal constant _P2 =
        '</text><text dx="76" dy="100" dominant-baseline="central" font-family="Black Ops One" textLength="300" font-weight="400" font-size="60" fill="#FF8A01">LifeScore</text><text dx="76" dy="230" dominant-baseline="central" font-family="Black Ops One" font-weight="400" font-size="120" fill="#FF8A01">';
    string internal constant _P3 =
        '</text><text dx="697" dy="425" dominant-baseline="central" font-family="VT323" font-weight="100" font-size="79" fill="#FFF">Re:';
    string internal constant _P4 =
        '</text><text dx="955" dy="425" dominant-baseline="central" font-family="VT323" font-weight="400" font-size="78" fill="#FFF">Age:';
    string internal constant _P5 =
        '</text><text dx="200" dy="425" dominant-baseline="central" text-anchor="left" font-family="VT323" font-weight="400" font-size="60" fill="#FFF">';
    string internal constant _P6 =
        '</text><text dx="975" dy="100" dominant-baseline="central" text-anchor="middle" style="height:100px" font-family="Black Ops One" font-size="56" fill="#FF8A01">DegenReborn</text><text dx="1070" dy="190" dominant-baseline="central" text-anchor="end" font-family="VT323" font-weight="400" font-size="80" fill="url(#prefix__p75)">';
    string internal constant _P7 =
        '</text><text dx="1070" dy="275" dominant-baseline="central" text-anchor="end" font-family="VT323" font-weight="400" font-size="80" fill="url(#prefix__p75)">';
    string internal constant _P8 =
        '</text><svg version="1.1" id="prefix__Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="1100" y="145" viewBox="0 13 1000 540" xml:space="preserve"><circle cx="32" cy="32" r="29.5" fill="#ECEFF0"/><path opacity=".2" fill-rule="evenodd" clip-rule="evenodd" d="M32 9.87L18 32.5l14 8 14-8L32 9.87z" fill="#828384"/><path d="M18 32.5L32 9.87V40.5l-14-8z" fill="#343535"/><path d="M46 32.5L32 9.87V40.5l14-8z" fill="#131313"/><path d="M18 32.5L32 9.87V26.5l-14 6z" fill="#828384"/><path d="M46 32.5L32 9.87V26.5l14 6zM46 34.5L32 43v11l14-19.5z" fill="#2F3030"/><path d="M18 34.5L32 43v11L18 34.5z" fill="#828384"/></svg>';

    string internal constant _P9 =
        '<path fill="#FFD058" d="M1125 256v5h-5v-5z"/><path fill="#E86609" d="M1145 256v5h-5v-5z"/><path fill="#F8C156" d="M1165 256v5h-5v-5z"/><path fill="#fff" d="M1115 256v5h-5v-5z"/><path fill="#E86609" d="M1135 256v5h-5v-5z"/><path fill="#F8C156" d="M1155 256v5h-5v-5z"/><path fill="#000" d="M1175 256v5h-5v-5zM1110 256v5h-5v-5z"/><path fill="#FFD058" d="M1130 256v5h-5v-5z"/><path fill="#C04A07" d="M1150 256v5h-5v-5z"/><path fill="#F29914" d="M1170 256v5h-5v-5z"/><path fill="#FFD058" d="M1120 256v5h-5v-5z"/><path fill="#E86609" d="M1140 256v5h-5v-5z"/><path fill="#F8C156" d="M1160 256v5h-5v-5z"/><path fill="#fff" d="M1125 246v5h-5v-5z"/><path fill="#F8C156" d="M1145 246v5h-5v-5z"/><path fill="#000" d="M1165 246v5h-5v-5z"/><path fill="#FFD058" d="M1135 246v5h-5v-5z"/><path fill="#F29914" d="M1155 246v5h-5v-5z"/><path fill="#fff" d="M1130 246v5h-5v-5z"/><path fill="#F8C156" d="M1150 246v5h-5v-5z"/><path fill="#000" d="M1120 246v5h-5v-5z"/><path fill="#FFD058" d="M1140 246v5h-5v-5z"/><path fill="#F29914" d="M1160 246v5h-5v-5z"/><path fill="#000" d="M1130 236h5v5h-5zM1105 266v5h-5v-5z"/><path fill="#FFD058" d="M1125 266v5h-5v-5z"/><path fill="#F8C156" d="M1145 266v5h-5v-5zM1165 266v5h-5v-5z"/><path fill="#FFD058" d="M1115 266v5h-5v-5z"/><path fill="#C04A07" d="M1135 266v5h-5v-5zM1155 266v5h-5v-5z"/><path fill="#F29914" d="M1175 266v5h-5v-5z"/><path fill="#fff" d="M1110 266v5h-5v-5z"/><path fill="#E86609" d="M1130 266v5h-5v-5zM1150 266v5h-5v-5z"/><path fill="#F8C156" d="M1170 266v5h-5v-5z"/><path fill="#FFD058" d="M1120 266v5h-5v-5zM1140 266v5h-5v-5z"/><path fill="#F8C156" d="M1160 266v5h-5v-5z"/><path fill="#000" d="M1180 266v5h-5v-5zM1125 241v5h-5v-5z"/><path fill="#F29914" d="M1145 241v5h-5v-5z"/><path fill="#fff" d="M1135 241v5h-5v-5z"/><path fill="#000" d="M1155 241v5h-5v-5zM1130 241v5h-5v-5z"/><path fill="#F29914" d="M1150 241v5h-5v-5z"/><path fill="#fff" d="M1140 241v5h-5v-5z"/><path fill="#000" d="M1160 241v5h-5v-5z"/><path fill="#FFD058" d="M1125 261v5h-5v-5z"/><path fill="#F8C056" d="M1145 261v5h-5v-5z"/><path fill="#F8C156" d="M1165 261v5h-5v-5z"/><path fill="#fff" d="M1115 261v5h-5v-5z"/><path fill="#C04A07" d="M1135 261v5h-5v-5zM1155 261v5h-5v-5z"/><path fill="#000" d="M1175 261v5h-5v-5zM1110 261v5h-5v-5z"/><path fill="#E86609" d="M1130 261v5h-5v-5zM1150 261v5h-5v-5z"/><path fill="#F29914" d="M1170 261v5h-5v-5z"/><path fill="#FFD058" d="M1120 261v5h-5v-5zM1140 261v5h-5v-5z"/><path fill="#F8C156" d="M1160 261v5h-5v-5z"/><path fill="#FFD058" d="M1125 251v5h-5v-5z"/><path fill="#F8C156" d="M1145 251v5h-5v-5z"/><path fill="#F29914" d="M1165 251v5h-5v-5z"/><path fill="#000" d="M1115 251v5h-5v-5z"/><path fill="#FFD058" d="M1135 251v5h-5v-5z"/><path fill="#F8C156" d="M1155 251v5h-5v-5z"/><path fill="#FFD058" d="M1130 251v5h-5v-5z"/><path fill="#F8C156" d="M1150 251v5h-5v-5z"/><path fill="#000" d="M1170 251v5h-5v-5z"/><path fill="#fff" d="M1120 251v5h-5v-5z"/><path fill="#FFD058" d="M1140 251v5h-5v-5z"/><path fill="#F8C156" d="M1160 251v5h-5v-5z"/><path fill="#000" d="M1135 236h5v5h-5zM1105 271v5h-5v-5z"/><path fill="#FFD058" d="M1125 271v5h-5v-5z"/><path fill="#E86609" d="M1145 271v5h-5v-5z"/><path fill="#F8C156" d="M1165 271v5h-5v-5z"/><path fill="#FFD058" d="M1115 271v5h-5v-5z"/><path fill="#E86609" d="M1135 271v5h-5v-5z"/><path fill="#F8C156" d="M1155 271v5h-5v-5z"/><path fill="#F29914" d="M1175 271v5h-5v-5z"/><path fill="#fff" d="M1110 271v5h-5v-5z"/><path fill="#E86609" d="M1130 271v5h-5v-5z"/><path fill="#C04A07" d="M1150 271v5h-5v-5z"/><path fill="#F8C156" d="M1170 271v5h-5v-5z"/><path fill="#FFD058" d="M1120 271v5h-5v-5z"/><path fill="#E86609" d="M1140 271v5h-5v-5z"/><path fill="#F8C156" d="M1160 271v5h-5v-5z"/><path fill="#000" d="M1180 271v5h-5v-5zM1140 236h5v5h-5zM1105 276v5h-5v-5z"/><path fill="#FFD058" d="M1125 276v5h-5v-5z"/><path fill="#F8C056" d="M1145 276v5h-5v-5z"/><path fill="#F8C156" d="M1165 276v5h-5v-5z"/><path fill="#FFD058" d="M1115 276v5h-5v-5z"/><path fill="#C04A07" d="M1135 276v5h-5v-5zM1155 276v5h-5v-5z"/><path fill="#F29914" d="M1175 276v5h-5v-5z"/><path fill="#fff" d="M1110 276v5h-5v-5z"/><path fill="#E86609" d="M1130 276v5h-5v-5zM1150 276v5h-5v-5z"/><path fill="#F8C156" d="M1170 276v5h-5v-5z"/><path fill="#FFD058" d="M1120 276v5h-5v-5zM1140 276v5h-5v-5z"/><path fill="#F8C156" d="M1160 276v5h-5v-5z"/><path fill="#000" d="M1180 276v5h-5v-5z"/><path fill="#FFD058" d="M1125 296v5h-5v-5z"/><path fill="#F8C156" d="M1145 296v5h-5v-5z"/><path fill="#F29914" d="M1165 296v5h-5v-5z"/><path fill="#000" d="M1115 296v5h-5v-5z"/><path fill="#FFD058" d="M1135 296v5h-5v-5z"/><path fill="#F8C156" d="M1155 296v5h-5v-5z"/><path fill="#FFD058" d="M1130 296v5h-5v-5z"/><path fill="#F8C156" d="M1150 296v5h-5v-5z"/><path fill="#000" d="M1170 296v5h-5v-5z"/><path fill="#fff" d="M1120 296v5h-5v-5z"/><path fill="#FFD058" d="M1140 296v5h-5v-5z"/><path fill="#F8C156" d="M1160 296v5h-5v-5z"/><path fill="#FFD058" d="M1125 286v5h-5v-5z"/><path fill="#F8C156" d="M1145 286v5h-5v-5zM1165 286v5h-5v-5z"/><path fill="#fff" d="M1115 286v5h-5v-5z"/><path fill="#C04A07" d="M1135 286v5h-5v-5z"/><path fill="#E86609" d="M1155 286v5h-5v-5z"/><path fill="#000" d="M1175 286v5h-5v-5zM1110 286v5h-5v-5z"/><path fill="#E86609" d="M1130 286v5h-5v-5z"/><path fill="#F8C056" d="M1150 286v5h-5v-5z"/><path fill="#F29914" d="M1170 286v5h-5v-5z"/><path fill="#FFD058" d="M1120 286v5h-5v-5zM1140 286v5h-5v-5z"/><path fill="#C04A07" d="M1160 286v5h-5v-5z"/><path fill="#000" d="M1125 306v5h-5v-5z"/><path fill="#F29914" d="M1145 306v5h-5v-5z"/><path fill="#FFE6A6" d="M1135 306v5h-5v-5z"/><path fill="#000" d="M1155 306v5h-5v-5zM1130 306v5h-5v-5z"/><path fill="#F29914" d="M1150 306v5h-5v-5z"/><path fill="#FFE6A6" d="M1140 306v5h-5v-5z"/><path fill="#000" d="M1160 306v5h-5v-5zM1145 236h5v5h-5zM1105 281v5h-5v-5z"/><path fill="#FFD058" d="M1125 281v5h-5v-5z"/><path fill="#F8C056" d="M1145 281v5h-5v-5z"/><path fill="#F8C156" d="M1165 281v5h-5v-5z"/><path fill="#FFD058" d="M1115 281v5h-5v-5z"/><path fill="#C04A07" d="M1135 281v5h-5v-5zM1155 281v5h-5v-5z"/><path fill="#F29914" d="M1175 281v5h-5v-5z"/><path fill="#fff" d="M1110 281v5h-5v-5z"/><path fill="#E86609" d="M1130 281v5h-5v-5zM1150 281v5h-5v-5z"/><path fill="#F8C156" d="M1170 281v5h-5v-5z"/><path fill="#FFD058" d="M1120 281v5h-5v-5zM1140 281v5h-5v-5z"/><path fill="#F8C156" d="M1160 281v5h-5v-5z"/><path fill="#000" d="M1180 281v5h-5v-5z"/><path fill="#fff" d="M1125 301v5h-5v-5z"/><path fill="#F8C156" d="M1145 301v5h-5v-5z"/><path fill="#000" d="M1165 301v5h-5v-5z"/><path fill="#FFD058" d="M1135 301v5h-5v-5z"/><path fill="#F29914" d="M1155 301v5h-5v-5z"/><path fill="#fff" d="M1130 301v5h-5v-5z"/><path fill="#F8C156" d="M1150 301v5h-5v-5z"/><path fill="#000" d="M1120 301v5h-5v-5z"/><path fill="#FFD058" d="M1140 301v5h-5v-5z"/><path fill="#F29914" d="M1160 301v5h-5v-5z"/><path fill="#FFD058" d="M1125 291v5h-5v-5z"/><path fill="#F8C156" d="M1145 291v5h-5v-5zM1165 291v5h-5v-5z"/><path fill="#fff" d="M1115 291v5h-5v-5z"/><path fill="#FFD058" d="M1135 291v5h-5v-5z"/><path fill="#F8C056" d="M1155 291v5h-5v-5z"/><path fill="#000" d="M1175 291v5h-5v-5zM1110 291v5h-5v-5z"/><path fill="#FFD058" d="M1130 291v5h-5v-5z"/><path fill="#F8C156" d="M1150 291v5h-5v-5z"/><path fill="#F29914" d="M1170 291v5h-5v-5z"/><path fill="#FFD058" d="M1120 291v5h-5v-5zM1140 291v5h-5v-5z"/><path fill="#F8C056" d="M1160 291v5h-5v-5z"/><path fill="#000" d="M1145 311v5h-5v-5zM1135 311v5h-5v-5zM1150 311v5h-5v-5zM1140 311v5h-5v-5z"/>';

    function P1() public pure returns (string memory) {
        return _P1;
    }

    function P2() public pure returns (string memory) {
        return _P2;
    }

    function P3() public pure returns (string memory) {
        return _P3;
    }

    function P4() public pure returns (string memory) {
        return _P4;
    }

    function P5() public pure returns (string memory) {
        return _P5;
    }

    function P6() public pure returns (string memory) {
        return _P6;
    }

    function P7() public pure returns (string memory) {
        return _P7;
    }

    function P8() public pure returns (string memory) {
        return _P8;
    }

    function P9() public pure returns (string memory) {
        return _P9;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";

library RenderConstant2 {

    string internal constant _P10 =
        '<svg xmlns="http://www.w3.org/2000/svg" x="72" y="380"><svg width="120" height="120"><clipPath id="prefix__clipCircle"><circle cx="48" cy="48" r="48"/></clipPath><circle cx="48" cy="48" r="48" fill="#C8145C"/><g clip-path="url(#prefix__clipCircle)"><path fill="#FA6000" d="M29.633 48.617l-86.61-83.057 83.056-86.611 86.611 83.057z"/><path fill="#F5AF00" d="M63.4 142.048l-119.678 8.788-8.788-119.677L54.61 22.37z"/><path fill="#03585E" d="M21.906-1.682l9.833 119.597-119.596 9.832L-97.69 8.151z"/></g></svg></svg><defs><linearGradient id="prefix__p0" x1="622.044" y1="-2.347" x2="622.044" y2="678.332" gradientUnits="userSpaceOnUse"><stop stop-color="#452F16"/><stop offset="1" stop-color="#1B2023"/></linearGradient><linearGradient id="prefix__p1" x1="622.044" y1="-2.347" x2="622.044" y2="668.943" gradientUnits="userSpaceOnUse"><stop stop-color="#FF8A00"/><stop offset="1" stop-color="#52391B"/></linearGradient><linearGradient id="prefix__p2" x1="622.171" y1="-1.73" x2="622.171" y2="347.827" gradientUnits="userSpaceOnUse"><stop stop-color="#F78602" stop-opacity=".35"/><stop offset="1" stop-color="#F78602" stop-opacity="0"/></linearGradient><linearGradient id="prefix__p75" x1="919" y1="180" x2="919" y2="276" gradientUnits="userSpaceOnUse"><stop stop-color="#FFFFDA"/><stop offset=".503" stop-color="#FFE7B6"/><stop offset="1" stop-color="#A87945"/></linearGradient><pattern id="prefix__pattern0" patternContentUnits="objectBoundingBox" width="1" height="1"><use xlink:href="#prefix__image0_539_2800" transform="matrix(.00255 0 0 .00255 -.639 -1.77)"/></pattern></defs><style>@font-face{font-family:&apos;Black Ops One&apos;;font-style:normal;font-weight:400;src:url(data:application/font;base64,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) format(&apos;woff2&apos;);unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}@font-face{font-family:&apos;VT323&apos;;font-style:normal;font-weight:400;src:url(data:application/font;base64,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) format(&apos;woff2&apos;)}</style></svg>';

 
    function P10() public pure returns (string memory) {
        return _P10;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {RenderConstant} from "src/library/RenderConstant.sol";
import {RenderConstant2} from "src/library/RenderConstant2.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IRebornDefinition} from "src/interfaces/IRebornPortal.sol";
import {strings} from "src/library/strings.sol";

library Renderer {
    using strings for *;

    function renderByTokenId(
        mapping(uint256 => IRebornDefinition.LifeDetail) storage details,
        uint256 tokenId
    ) public view returns (string memory) {
        string memory metadata = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "',
                    "Degen Tombstone",
                    '","description":"',
                    "",
                    '","image":"',
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            renderSvg(
                                details[tokenId].seed,
                                details[tokenId].score,
                                details[tokenId].round,
                                details[tokenId].age,
                                details[tokenId].creatorName,
                                details[tokenId].nativeCost,
                                details[tokenId].rebornCost
                            )
                        )
                    ),
                    '","attributes": ',
                    renderTrait(
                        details[tokenId].seed,
                        details[tokenId].score,
                        details[tokenId].round,
                        details[tokenId].age,
                        details[tokenId].creator,
                        details[tokenId].creatorName,
                        details[tokenId].reward,
                        details[tokenId].nativeCost
                    ),
                    "}"
                )
            )
        );

        return string.concat("data:application/json;base64,", metadata);
    }

    function renderSvg(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age,
        string memory creatorName,
        uint256 nativeCost,
        uint256 rebornCost
    ) public pure returns (string memory) {
        string memory Part1 = _renderSvgPart1(seed, lifeScore, round, age);
        string memory Part2 = _renderSvgPart2(
            creatorName,
            nativeCost,
            rebornCost
        );

        return string(abi.encodePacked(Part1, Part2));
    }

    function renderTrait(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age,
        address creator,
        string memory creatorName,
        uint256 reward,
        uint256 cost
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _renderTraitPart1(seed, lifeScore, round, age),
                    _renderTraitPart2(creator, creatorName, reward, cost)
                )
            );
    }

    function _renderTraitPart1(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '[{"trait_type": "Seed", "value": "',
                    Strings.toHexString(uint256(seed), 32),
                    '"},{"trait_type": "Life Score", "value": ',
                    Strings.toString(lifeScore),
                    '},{"trait_type": "Round", "value": ',
                    Strings.toString(round),
                    '},{"trait_type": "Age", "value": ',
                    Strings.toString(age)
                )
            );
    }

    function _renderTraitPart2(
        address creator,
        string memory creatorName,
        uint256 reward,
        uint256 cost
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '},{"trait_type": "Creator", "value": "',
                    Strings.toHexString(uint160(creator), 20),
                    '"},{"trait_type": "CreatorName", "value": "',
                    creatorName,
                    '"},{"trait_type": "Reward", "value": ',
                    Strings.toString(reward),
                    '},{"trait_type": "Cost", "value": ',
                    Strings.toString(cost),
                    "}]"
                )
            );
    }

    function _renderSvgPart1(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RenderConstant.P1(),
                    _transformBytes32Seed(seed),
                    RenderConstant.P2(),
                    _transformUint256(lifeScore),
                    RenderConstant.P3(),
                    Strings.toString(round),
                    RenderConstant.P4(),
                    Strings.toString(age)
                )
            );
    }

    function _renderSvgPart2(
        string memory creator,
        uint256 nativeCost,
        uint256 degenCost
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RenderConstant.P5(),
                    _compressUtf8(creator),
                    RenderConstant.P6(),
                    // Complete accuracy
                    _transformWeiToDecimal2(nativeCost * 10 ** 12),
                    RenderConstant.P7(),
                    _transformUint256(degenCost / 1 ether),
                    RenderConstant.P8(),
                    RenderConstant.P9(),
                    RenderConstant2.P10()
                )
            );
    }

    function _transformWeiToDecimal2(
        uint256 value
    ) public pure returns (string memory str) {
        if (value > 100 ether) {
            return Strings.toString(value / 1 ether);
        } else {
            uint256 secondFractional = value % (1 ether / 10);
            uint256 firstFractional = (value - secondFractional) % (1 ether);
            uint256 integer;
            if (firstFractional != 0 || secondFractional != 0) {
                integer = value - firstFractional - secondFractional;
            } else {
                integer = value;
            }

            return
                string.concat(
                    Strings.toString(integer / 1 ether),
                    ".",
                    Strings.toString(firstFractional / 10 ** 17),
                    Strings.toString(secondFractional / 10 ** 16)
                );
        }
    }

    function _transformUint256(
        uint256 value
    ) public pure returns (string memory str) {
        if (value < 10 ** 7) {
            return _recursiveAddComma(value);
        } else if (value < 10 ** 11) {
            return
                string(
                    abi.encodePacked(_recursiveAddComma(value / 10 ** 6), "M")
                );
        } else if (value < 10 ** 15) {
            return
                string(
                    abi.encodePacked(_recursiveAddComma(value / 10 ** 9), "B")
                );
        } else {
            revert ValueOutOfRange();
        }
    }

    function _recursiveAddComma(
        uint256 value
    ) internal pure returns (string memory str) {
        if (value / 1000 == 0) {
            str = string(abi.encodePacked(Strings.toString(value), str));
        } else {
            str = string(
                abi.encodePacked(
                    _recursiveAddComma(value / 1000),
                    ",",
                    _numberStringToLengthThree(Strings.toString(value % 1000)),
                    str
                )
            );
        }
    }

    function _transformBytes32Seed(
        bytes32 b
    ) public pure returns (string memory) {
        string memory str = Strings.toHexString(uint256(b), 32);
        return
            string(
                abi.encodePacked(
                    _substring(str, 0, 14),
                    unicode"…",
                    _substring(str, 45, 66)
                )
            );
    }

    function _numberStringToLengthThree(
        string memory number
    ) internal pure returns (string memory) {
        if (bytes(number).length == 1) {
            return string(abi.encodePacked("00", number));
        } else if (bytes(number).length == 2) {
            return string(abi.encodePacked("0", number));
        } else {
            return number;
        }
    }

    error ValueOutOfRange();

    function _shortenAddr(address addr) private pure returns (string memory) {
        uint256 value = uint160(addr);
        bytes memory allBytes = bytes(Strings.toHexString(value, 20));

        string memory newString = string(allBytes);

        return
            string(
                abi.encodePacked(
                    _substring(newString, 0, 6),
                    unicode"…",
                    _substring(newString, 38, 42)
                )
            );
    }

    function _substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _compressUtf8(
        string memory str
    ) public pure returns (string memory res) {
        strings.slice memory sl = str.toSlice();
        strings.slice memory resl = res.toSlice();

        uint256 length = sl.len();
        if (length > 12) {
            for (uint256 i = 0; i < 5; i++) {
                resl = resl.concat(sl.nextRune()).toSlice();
            }
            for (uint256 i = 5; i < length - 7; i++) {
                sl.nextRune().toString();
            }

            resl = resl.concat(unicode"…".toSlice()).toSlice();
            for (uint256 i = length - 7; i < length; i++) {
                resl = resl.concat(sl.nextRune()).toSlice();
            }
            return resl.toString();
        }
        return str;
    }
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0) return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(
        slice memory self,
        slice memory other
    ) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len) shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if (shortest < 32) {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0) return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(
        slice memory self,
        slice memory other
    ) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(
        slice memory self,
        slice memory rune
    ) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly {
            b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
        }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(
        slice memory self
    ) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly {
            word := mload(mload(add(self, 32)))
        }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint selflen,
        uint selfptr,
        uint needlelen,
        uint needleptr
    ) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(
        uint selflen,
        uint selfptr,
        uint needlelen,
        uint needleptr
    ) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr) return selfptr;
                    ptr--;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(
        slice memory self,
        slice memory needle
    ) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) +
            needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr =
                findPtr(
                    self._len - (ptr - self._ptr),
                    ptr,
                    needle._len,
                    needle._ptr
                ) +
                needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        return
            rfindPtr(self._len, self._ptr, needle._len, needle._ptr) !=
            self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(
        slice memory self,
        slice memory other
    ) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(
        slice memory self,
        slice[] memory parts
    ) internal pure returns (string memory) {
        if (parts.length == 0) return "";

        uint length = self._len * (parts.length - 1);
        for (uint i = 0; i < parts.length; i++) length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }

        for (uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }
    error InvalidSignature();
    error InvalidSignatureLength();
    error InvalidSignatureSValue();

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert InvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert InvalidSignatureLength();
        } else if (error == RecoverError.InvalidSignatureS) {
            revert InvalidSignatureSValue();
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
    function tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address, RecoverError) {
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
    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
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
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
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
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
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
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
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
    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(
        bytes memory s
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    StringsUpgradeable.toString(s.length),
                    s
                )
            );
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
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMapsUpgradeable {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(
        BitMap storage bitmap,
        uint256 index
    ) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(BitMap storage bitmap, uint256 index, bool value) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
import {IRebornDefinition} from "src/interfaces/IRebornPortal.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IRewardVault} from "src/RewardVault.sol";
import {CommonError} from "src/library/CommonError.sol";
import {ECDSAUpgradeable} from "src/oz/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IAirdropVault} from "src/AirdropVault.sol";
import {IRegistry} from "src/Registry.sol";

library PortalLib {
    uint256 public constant PERSHARE_BASE = 10e18;
    // percentage base of refer reward fees
    uint256 public constant PERCENTAGE_BASE = 10000;

    bytes32 public constant _SOUPPARAMS_TYPEHASH =
        keccak256(
            "AuthenticateSoupArg(address user,uint256 soupPrice,uint256 incarnateCounter,uint256 tokenId,uint256 deadline)"
        );

    bytes32 public constant _EXHUME_TYPEHASH =
        keccak256(
            "ExhumeArg(address exhumer,address exhumee,uint256 tokenId,uint256 nonce,uint256 nativeCost,uint256 degenCost,uint256 shovelTokenId,uint256 deadline)"
        );

    bytes32 public constant _CLAIM_TYPEHASH =
        keccak256(
            "ClaimRewardArg(address user,uint256 amount,uint256 type,uint256 nonce,uint256 deadline)"
        );

    bytes32 public constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    uint256 public constant ONE_HUNDRED = 100;

    struct CharacterParams {
        uint256 maxAP;
        uint256 restoreTimePerAP;
        uint256 level;
    }

    // TODO: use more compact storage
    struct CharacterProperty {
        uint8 currentAP;
        uint8 maxAP;
        uint24 restoreTimePerAP; // Time Needed to Restore One Action Point
        uint32 lastTimeAPUpdate;
        uint8 level;
    }

    struct CurrentAPReturn {
        uint256 currentAP;
        uint256 lastAPUpdateTime;
    }

    enum RewardType {
        NativeToken,
        RebornToken
    }

    struct ReferrerRewardFees {
        uint16 incarnateRef1Fee;
        uint16 incarnateRef2Fee;
        uint16 vaultRef1Fee;
        uint16 vaultRef2Fee;
        uint192 _slotPlaceholder;
    }

    struct Pool {
        uint256 totalAmount;
        uint256 accRebornPerShare;
        uint256 accNativePerShare;
        uint128 droppedRebornTotal;
        uint128 droppedNativeTotal;
        uint256 coindayCumulant;
        uint32 coindayUpdateLastTime;
        uint112 totalForwardTribute;
        uint112 totalReverseTribute;
        uint32 lastDropNativeTime;
        uint32 lastDropRebornTime;
        uint128 validTVL;
        uint64 placeholder;
    }

    //
    // We do some fancy math here. Basically, any point in time, the amount
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (Amount * pool.accPerShare) - user.rewardDebt
    //
    // Whenever a user infuse or switchPool. Here's what happens:
    //   1. The pool's `accPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
    struct Portfolio {
        uint256 accumulativeAmount;
        uint128 rebornRewardDebt;
        uint128 nativeRewardDebt;
        /// @dev reward for holding the NFT when the NFT is selected
        uint128 pendingOwnerRebornReward;
        uint128 pendingOwnerNativeReward;
        uint256 coindayCumulant;
        uint32 coindayUpdateLastTime;
        uint112 totalForwardTribute;
        uint112 totalReverseTribute;
    }

    event SignerUpdate(address signer, bool valid);
    event ReferReward(
        address indexed user,
        address indexed ref1,
        uint256 amount1,
        address indexed ref2,
        uint256 amount2,
        RewardType rewardType
    );

    function _toLastHour(uint256 timestamp) public pure returns (uint256) {
        return timestamp - (timestamp % (1 hours));
    }

    /**
     * @dev returns referrer and referrer reward
     * @return ref1  level1 of referrer. direct referrer
     * @return ref1Reward  level 1 referrer reward
     * @return ref2  level2 of referrer. referrer's referrer
     * @return ref2Reward  level 2 referrer reward
     */
    function _calculateReferReward(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        address account,
        uint256 amount,
        RewardType rewardType
    )
        public
        view
        returns (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        )
    {
        ref1 = referrals[account];
        ref2 = referrals[ref1];

        if (rewardType == RewardType.NativeToken) {
            ref1Reward = ref1 == address(0)
                ? 0
                : (amount * rewardFees.incarnateRef1Fee) / PERCENTAGE_BASE;
            ref2Reward = ref2 == address(0)
                ? 0
                : (amount * rewardFees.incarnateRef2Fee) / PERCENTAGE_BASE;
        }

        if (rewardType == RewardType.RebornToken) {
            ref1Reward = ref1 == address(0)
                ? 0
                : (amount * rewardFees.vaultRef1Fee) / PERCENTAGE_BASE;
            ref2Reward = ref2 == address(0)
                ? 0
                : (amount * rewardFees.vaultRef2Fee) / PERCENTAGE_BASE;
        }
    }

    /**
     * @dev send NativeToken to referrers
     */
    function _sendNativeRewardToRefs(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        mapping(address => mapping(IRebornDefinition.RewardToClaimType => IRebornDefinition.RewardStore))
            storage _rewardToClaim,
        address account,
        uint256 amount
    ) public returns (uint256 total) {
        (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        ) = _calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                RewardType.NativeToken
            );

        unchecked {
            _rewardToClaim[ref1][
                IRebornDefinition.RewardToClaimType.ReferNative
            ].totalReward += ref1Reward;
            _rewardToClaim[ref2][
                IRebornDefinition.RewardToClaimType.ReferNative
            ].totalReward += ref2Reward;
        }

        unchecked {
            total = ref1Reward + ref2Reward;
        }

        emit ReferReward(
            account,
            ref1,
            ref1Reward,
            ref2,
            ref2Reward,
            RewardType.NativeToken
        );
    }

    /**
     * @dev vault $REBORN token to referrers
     */
    function _rewardDegenRewardToRefs(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        mapping(address => mapping(IRebornDefinition.RewardToClaimType => IRebornDefinition.RewardStore))
            storage _rewardToClaim,
        address account,
        uint256 amount
    ) public {
        (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        ) = _calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                RewardType.RebornToken
            );

        unchecked {
            _rewardToClaim[ref1][IRebornDefinition.RewardToClaimType.ReferDegen]
                .totalReward += ref1Reward;
            _rewardToClaim[ref2][IRebornDefinition.RewardToClaimType.ReferDegen]
                .totalReward += ref2Reward;
        }

        emit ReferReward(
            account,
            ref1,
            ref1Reward,
            ref2,
            ref2Reward,
            RewardType.RebornToken
        );
    }

    function _calculateCurrentAP(
        CharacterProperty memory charProperty
    ) public view returns (CurrentAPReturn memory) {
        // if restoreTimePerAP is not set, no process
        if (charProperty.restoreTimePerAP == 0) {
            return
                CurrentAPReturn(
                    charProperty.currentAP,
                    charProperty.lastTimeAPUpdate
                );
        }

        uint256 calculatedRestoreAp = (block.timestamp -
            charProperty.lastTimeAPUpdate) / charProperty.restoreTimePerAP;

        uint256 calculatedCurrentAP = calculatedRestoreAp +
            charProperty.currentAP;

        uint256 lastAPUpdateTime = charProperty.lastTimeAPUpdate +
            calculatedRestoreAp *
            charProperty.restoreTimePerAP;

        uint256 currentAP;

        // min(calculatedCurrentAP, maxAp)
        if (calculatedCurrentAP <= charProperty.maxAP) {
            currentAP = calculatedCurrentAP;
        } else {
            currentAP = charProperty.maxAP;
        }

        return CurrentAPReturn(currentAP, lastAPUpdateTime);
    }

    function _consumeAP(
        uint256 tokenId,
        mapping(uint256 => CharacterProperty) storage _characterProperties
    ) public {
        CharacterProperty storage charProperty = _characterProperties[tokenId];

        CurrentAPReturn memory car = _calculateCurrentAP(charProperty);

        // if current ap is max, recover starts from now
        if (car.currentAP == charProperty.maxAP) {
            charProperty.lastTimeAPUpdate = uint32(block.timestamp);
        } else {
            charProperty.lastTimeAPUpdate = uint32(car.lastAPUpdateTime);
        }

        // Reduce AP
        charProperty.currentAP = uint8(car.currentAP - 1);
    }

    function _useSoupParam(
        IRebornDefinition.SoupParams calldata soupParams,
        uint256 nonce,
        mapping(uint256 => PortalLib.CharacterProperty)
            storage _characterProperties,
        address registry
    ) public {
        _checkSoupSig(soupParams, nonce, registry);

        if (soupParams.charTokenId != 0) {
            // use degen2009 nft character
            _consumeAP(soupParams.charTokenId, _characterProperties);
        }
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _altarDomainSeparatorV4() public view returns (bytes32) {
        return
            _buildDomainSeparator(
                PortalLib._TYPE_HASH,
                keccak256("Altar"),
                keccak256("1")
            );
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _degenPortalDomainSeparatorV4() public view returns (bytes32) {
        return
            _buildDomainSeparator(
                PortalLib._TYPE_HASH,
                keccak256("DegenPortal"),
                keccak256("1")
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _checkExhumeSig(
        IRebornDefinition.ExhumeParams calldata exhumeParams,
        uint256 nonce,
        address registry
    ) public view {
        if (block.timestamp >= exhumeParams.deadline) {
            revert CommonError.SignatureExpired();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PortalLib._EXHUME_TYPEHASH,
                msg.sender,
                exhumeParams.exhumee,
                exhumeParams.tokenId,
                nonce,
                exhumeParams.nativeCost,
                exhumeParams.degenCost,
                exhumeParams.shovelTokenId,
                exhumeParams.deadline
            )
        );

        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(
            _degenPortalDomainSeparatorV4(),
            structHash
        );

        address signer = ECDSAUpgradeable.recover(
            hash,
            exhumeParams.v,
            exhumeParams.r,
            exhumeParams.s
        );

        if (!IRegistry(registry).checkIsSigner(signer)) {
            revert CommonError.NotSigner();
        }
    }

    function _checkClaimRewardSig(
        IRebornDefinition.ClaimRewardParams calldata claimRewardParams,
        uint256 nonce,
        address registry
    ) public view {
        if (block.timestamp >= claimRewardParams.deadline) {
            revert CommonError.SignatureExpired();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PortalLib._CLAIM_TYPEHASH,
                claimRewardParams.user,
                claimRewardParams.amount,
                claimRewardParams.t,
                nonce,
                claimRewardParams.deadline
            )
        );

        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(
            _degenPortalDomainSeparatorV4(),
            structHash
        );

        address signer = ECDSAUpgradeable.recover(
            hash,
            claimRewardParams.v,
            claimRewardParams.r,
            claimRewardParams.s
        );

        if (!IRegistry(registry).checkIsSigner(signer)) {
            revert CommonError.NotSigner();
        }
    }

    function _checkSoupSig(
        IRebornDefinition.SoupParams calldata soupParams,
        uint256 nonce,
        address registry
    ) public view {
        if (block.timestamp >= soupParams.deadline) {
            revert CommonError.SignatureExpired();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PortalLib._SOUPPARAMS_TYPEHASH,
                msg.sender,
                soupParams.soupPrice,
                nonce,
                soupParams.charTokenId,
                soupParams.deadline
            )
        );

        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(
            _altarDomainSeparatorV4(),
            structHash
        );

        address signer = ECDSAUpgradeable.recover(
            hash,
            soupParams.v,
            soupParams.r,
            soupParams.s
        );

        if (!IRegistry(registry).checkIsSigner(signer)) {
            revert CommonError.NotSigner();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import {IRegistry} from "src/interfaces/IRegistry.sol";
import {CommonError} from "src/library/CommonError.sol";

contract Registry is IRegistry, UUPSUpgradeable, SafeOwnableUpgradeable {
    event DegenSet(address degen);
    event PortalSet(address portal);
    event ShovelSet(address shovel);
    event PiggyBankSet(address piggyBank);

    mapping(address => bool) private _signers;
    address private _degen;
    address private _portal;
    address private _shovel;
    address private _piggyBank;

    uint256[45] private __gap;

    function initialize(address owner_) public initializer {
        if (owner_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }
        __Ownable_init_unchained(owner_);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev update signers
     * @param toAdd list of to be added signer
     * @param toRemove list of to be removed signer
     */
    function updateSigners(
        address[] calldata toAdd,
        address[] calldata toRemove
    ) public onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            _signers[toAdd[i]] = true;
            emit SignerUpdate(toAdd[i], true);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete _signers[toRemove[i]];
            emit SignerUpdate(toRemove[i], false);
        }
    }

    function setDegen(address addr) public onlyOwner {
        _degen = addr;
        emit DegenSet(address(addr));
    }

    function setPortal(address addr) public onlyOwner {
        _portal = addr;
        emit PortalSet(address(addr));
    }

    function setShovel(address addr) public onlyOwner {
        _shovel = addr;
        emit ShovelSet(address(addr));
    }

    function setPiggyBank(address addr) public onlyOwner {
        _piggyBank = addr;
        emit PiggyBankSet(address(addr));
    }

    function checkIsSigner(address addr) public override view returns (bool) {
        return _signers[addr];
    }

    function getDegen() public view override returns (address) {
        return _degen;
    }

    function getPortal() public view override returns (address) {
        return _portal;
    }

    function getShovel() public view override returns (address) {
        return _shovel;
    }

    function getPiggyBank() public view override returns (address) {
        return _piggyBank;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IRewardVault} from "src/interfaces/IRewardVault.sol";

contract RewardVault is IRewardVault, Ownable {
    using SafeERC20 for IERC20;

    address public immutable rebornToken;

    constructor(address owner_, address rebornToken_) {
        if (rebornToken_ == address(0)) revert ZeroAddressSet();
        _transferOwnership(owner_);
        rebornToken = rebornToken_;
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function reward(
        address to,
        uint256 amount
    ) external virtual override onlyOwner {
        IERC20(rebornToken).safeTransfer(to, amount);
    }

    /**
     * @notice withdraw token Emergency
     */
    function withdrawEmergency(address to) external virtual override onlyOwner {
        if (to == address(0)) revert ZeroAddressSet();
        IERC20(rebornToken).safeTransfer(
            to,
            IERC20(rebornToken).balanceOf(address(this))
        );
        emit WithdrawEmergency(
            rebornToken,
            IERC20(rebornToken).balanceOf(address(this))
        );
    }
}