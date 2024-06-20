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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../libraries/PrecisionUtils.sol";
import "../interfaces/IPool.sol";

library TokenHelper {
    using PrecisionUtils for uint256;
    using SafeMath for uint256;

    function convertIndexAmountToStable(
        IPool.Pair memory pair,
        int256 indexTokenAmount
    ) internal view returns (int256 amount) {
        if (indexTokenAmount == 0) return 0;

        uint8 stableTokenDec = IERC20Metadata(pair.stableToken).decimals();
        return convertTokenAmountTo(pair.indexToken, indexTokenAmount, stableTokenDec);
    }

    function convertIndexAmountToStableWithPrice(
        IPool.Pair memory pair,
        int256 indexTokenAmount,
        uint256 price
    ) internal view returns (int256 amount) {
        if (indexTokenAmount == 0) return 0;

        uint8 stableTokenDec = IERC20Metadata(pair.stableToken).decimals();
        return convertTokenAmountWithPrice(pair.indexToken, indexTokenAmount, stableTokenDec, price);
    }

    function convertTokenAmountWithPrice(
        address token,
        int256 tokenAmount,
        uint8 targetDecimals,
        uint256 price
    ) internal view returns (int256 amount) {
        if (tokenAmount == 0) return 0;

        uint256 tokenDec = uint256(IERC20Metadata(token).decimals());

        uint256 tokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - tokenDec);
        uint256 targetTokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - targetDecimals);

        amount = (tokenAmount * int256(tokenWad)) * int256(price) / int256(targetTokenWad) / int256(PrecisionUtils.PRICE_PRECISION);
    }

    function convertStableAmountToIndex(
        IPool.Pair memory pair,
        int256 stableTokenAmount
    ) internal view returns (int256 amount) {
        if (stableTokenAmount == 0) return 0;

        uint8 indexTokenDec = IERC20Metadata(pair.indexToken).decimals();
        return convertTokenAmountTo(pair.stableToken, stableTokenAmount, indexTokenDec);
    }

    function convertTokenAmountTo(
        address token,
        int256 tokenAmount,
        uint8 targetDecimals
    ) internal view returns (int256 amount) {
        if (tokenAmount == 0) return 0;

        uint256 tokenDec = uint256(IERC20Metadata(token).decimals());

        uint256 tokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - tokenDec);
        uint256 targetTokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - targetDecimals);
        amount = (tokenAmount * int256(tokenWad)) / int256(targetTokenWad);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IPool.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";
import "../libraries/PrecisionUtils.sol";
import "../libraries/TradingTypes.sol";

library ValidationHelper {
    using PrecisionUtils for uint256;

    function validateAccountBlacklist(
        IAddressesProvider addressesProvider,
        address account
    ) internal view {
        require(
            !IRoleManager(addressesProvider.roleManager()).isBlackList(account),
            "blacklist account"
        );
    }

    function validatePriceTriggered(
        IPool.TradingConfig memory tradingConfig,
        TradingTypes.TradeType tradeType,
        bool isIncrease,
        bool isLong,
        bool isAbove,
        uint256 currentPrice,
        uint256 orderPrice,
        uint256 maxSlippage
    ) internal pure {
        if (tradeType == TradingTypes.TradeType.MARKET) {
            bool valid;
            if ((isIncrease && isLong) || (!isIncrease && !isLong)) {
                valid = currentPrice <= orderPrice.mulPercentage(PrecisionUtils.percentage() + maxSlippage);
            } else {
                valid = currentPrice >= orderPrice.mulPercentage(PrecisionUtils.percentage() - maxSlippage);
            }
            require(maxSlippage == 0 || valid, "exceeds max slippage");
        } else if (tradeType == TradingTypes.TradeType.LIMIT) {
            require(
                isAbove
                    ? currentPrice.mulPercentage(
                        PrecisionUtils.percentage() - tradingConfig.priceSlipP
                    ) <= orderPrice
                    : currentPrice.mulPercentage(
                        PrecisionUtils.percentage() + tradingConfig.priceSlipP
                    ) >= orderPrice,
                "not reach trigger price"
            );
        } else {
            require(
                isAbove ? currentPrice <= orderPrice : currentPrice >= orderPrice,
                "not reach trigger price"
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IAddressesProvider {
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    function WETH() external view returns (address);

    function timelock() external view returns (address);

    function priceOracle() external view returns (address);

    function indexPriceOracle() external view returns (address);

    function fundingRate() external view returns (address);

    function executionLogic() external view returns (address);

    function liquidationLogic() external view returns (address);

    function roleManager() external view returns (address);

    function backtracker() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IPool.sol";
import "../libraries/TradingTypes.sol";
import "./IPositionManager.sol";

interface IFeeCollector {

    event UpdatedTradingFeeTier(
        address sender,
        uint8 tier,
        uint256 oldTakerFee,
        int256 oldMakerFee,
        uint256 newTakerFee,
        int256 newMakerFee
    );

    event UpdateMaxReferralsRatio(uint256 oldRatio, uint256 newRatio);

    event UpdatedStakingPoolAddress(address sender, address oldAddress, address newAddress);
    event UpdatePoolAddress(address sender, address oldAddress, address newAddress);
    event UpdatePledgeAddress(address sender, address oldAddress, address newAddress);

    event UpdatedPositionManagerAddress(address sender, address oldAddress, address newAddress);

    event UpdateExecutionLogicAddress(address sender, address oldAddress, address newAddress);

    event DistributeTradingFeeV2(
        address account,
        uint256 pairIndex,
        uint256 orderId,
        uint256 sizeDelta,
        uint256 regularTradingFee,
        bool isMaker,
        int256 feeRate,
        int256 vipTradingFee,
        uint256 returnAmount,
        uint256 referralsAmount,
        uint256 referralUserAmount,
        address referralOwner,
        int256 lpAmount,
        int256 keeperAmount,
        int256 stakingAmount,
        int256 reservedAmount,
        int256 ecoFundAmount,
        int256 treasuryAmount
    );

    event ClaimedStakingTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedDistributorTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedReferralsTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedUserTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedKeeperTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedKeeperNetworkFee(address account, address claimToken, uint256 amount);

    struct TradingFeeTier {
        int256 makerFee;
        uint256 takerFee;
    }

    function maxReferralsRatio() external view returns (uint256 maxReferenceRatio);

    function stakingTradingFee() external view returns (uint256);
    function stakingTradingFeeDebt() external view returns (uint256);

    function treasuryFee() external view returns (uint256);

    function treasuryFeeDebt() external view returns (uint256);

    function reservedTradingFee() external view returns (int256);

    function ecoFundTradingFee() external view returns (int256);

    function userTradingFee(address _account) external view returns (uint256);

    function keeperTradingFee(address _account) external view returns (int256);

    function referralFee(address _referralOwner) external view returns (uint256);

    function getTradingFeeTier(uint256 pairIndex, uint8 tier) external view returns (TradingFeeTier memory);

    function getRegularTradingFeeTier(uint256 pairIndex) external view returns (TradingFeeTier memory);

    function getKeeperNetworkFee(
        address account,
        TradingTypes.InnerPaymentType paymentType
    ) external view returns (uint256);

    function updateMaxReferralsRatio(uint256 newRatio) external;

    function claimStakingTradingFee() external returns (uint256);

    function claimTreasuryFee() external returns (uint256);

    function claimReferralFee() external returns (uint256);

    function claimUserTradingFee() external returns (uint256);

    function claimKeeperTradingFee() external returns (uint256);

    function claimKeeperNetworkFee(
        TradingTypes.InnerPaymentType paymentType
    ) external returns (uint256);

    struct RescueKeeperNetworkFee {
        address keeper;
        address receiver;
    }

    function rescueKeeperNetworkFee(
        TradingTypes.InnerPaymentType paymentType,
        RescueKeeperNetworkFee[] calldata rescues
    ) external;

    function distributeTradingFee(
        IPool.Pair memory pair,
        address account,
        uint256 orderId,
        address keeper,
        uint256 size,
        uint256 sizeDelta,
        uint256 executionPrice,
        uint256 tradingFee,
        bool isMaker,
        TradingFeeTier memory tradingFeeTier,
        int256 exposureAmount,
        int256 afterExposureAmount,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) external returns (int256 lpAmount, int256 vipTradingFee, uint256 givebackFeeAmount);

    function distributeNetworkFee(
        address keeper,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ILiquidityCallback {
    function addLiquidityCallback(
        address indexToken,
        address stableToken,
        uint256 amountIndex,
        uint256 amountStable,
        bytes calldata data
    ) external;

    function removeLiquidityCallback(address poolToken, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IPriceFeed} from "./IPriceFeed.sol";

interface IOraclePriceFeed is IPriceFeed {

    function updateHistoricalPrice(
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64 backtrackRound
    ) external payable;

    function removeHistoricalPrice(
        uint64 backtrackRound,
        address[] calldata tokens
    ) external;

    function getHistoricalPrice(
        uint64 backtrackRound,
        address token
    ) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPool {
    // Events
    event PairAdded(
        address indexed indexToken,
        address indexed stableToken,
        address lpToken,
        uint256 index
    );

    event UpdateTotalAmount(
        uint256 indexed pairIndex,
        int256 indexAmount,
        int256 stableAmount,
        uint256 indexTotalAmount,
        uint256 stableTotalAmount
    );

    event UpdateReserveAmount(
        uint256 indexed pairIndex,
        int256 indexAmount,
        int256 stableAmount,
        uint256 indexReservedAmount,
        uint256 stableReservedAmount
    );

    event UpdateLPProfit(
        uint256 indexed pairIndex,
        address token,
        int256 profit,
        uint256 totalAmount
    );

    event GivebackTradingFee(
        uint256 indexed pairIndex,
        address token,
        uint256 amount
    );

    event UpdateAveragePrice(uint256 indexed pairIndex, uint256 averagePrice);

    event UpdateSpotSwap(address sender, address oldAddress, address newAddress);

    event UpdatePoolView(address sender, address oldAddress, address newAddress);

    event UpdateRouter(address sender, address oldAddress, address newAddress);

    event UpdateRiskReserve(address sender, address oldAddress, address newAddress);

    event UpdateFeeCollector(address sender, address oldAddress, address newAddress);

    event UpdatePositionManager(address sender, address oldAddress, address newAddress);

    event UpdateOrderManager(address sender, address oldAddress, address newAddress);

    event AddStableToken(address sender, address token);

    event RemoveStableToken(address sender, address token);

    event AddLiquidity(
        address indexed recipient,
        uint256 indexed pairIndex,
        uint256 indexAmount,
        uint256 stableAmount,
        uint256 lpAmount,
        uint256 indexFeeAmount,
        uint256 stableFeeAmount,
        address slipToken,
        uint256 slipFeeAmount,
        uint256 lpPrice
    );

    event RemoveLiquidity(
        address indexed recipient,
        uint256 indexed pairIndex,
        uint256 indexAmount,
        uint256 stableAmount,
        uint256 lpAmount,
        uint256 feeAmount,
        uint256 lpPrice
    );

    event ClaimedFee(address sender, address token, uint256 amount);

    struct Vault {
        uint256 indexTotalAmount; // total amount of tokens
        uint256 indexReservedAmount; // amount of tokens reserved for open positions
        uint256 stableTotalAmount;
        uint256 stableReservedAmount;
        uint256 averagePrice;
    }

    struct Pair {
        uint256 pairIndex;
        address indexToken;
        address stableToken;
        address pairToken;
        bool enable;
        uint256 kOfSwap; //Initial k value of liquidity
        uint256 expectIndexTokenP; //   for 100%
        uint256 maxUnbalancedP;
        uint256 unbalancedDiscountRate;
        uint256 addLpFeeP; // Add liquidity fee
        uint256 removeLpFeeP; // remove liquidity fee
    }

    struct TradingConfig {
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 minTradeAmount;
        uint256 maxTradeAmount;
        uint256 maxPositionAmount;
        uint256 maintainMarginRate; // Maintain the margin rate of  for 100%
        uint256 priceSlipP; // Price slip point
        uint256 maxPriceDeviationP; // Maximum offset of index price
    }

    struct TradingFeeConfig {
        uint256 lpFeeDistributeP;
        uint256 stakingFeeDistributeP;
        uint256 keeperFeeDistributeP;
        uint256 treasuryFeeDistributeP;
        uint256 reservedFeeDistributeP;
        uint256 ecoFundFeeDistributeP;
    }

    function pairsIndex() external view returns (uint256);

    function getPairIndex(address indexToken, address stableToken) external view returns (uint256);

    function getPair(uint256) external view returns (Pair memory);

    function getTradingConfig(uint256 _pairIndex) external view returns (TradingConfig memory);

    function getTradingFeeConfig(uint256) external view returns (TradingFeeConfig memory);

    function getVault(uint256 _pairIndex) external view returns (Vault memory vault);

    function transferTokenTo(address token, address to, uint256 amount) external;

    function transferEthTo(address to, uint256 amount) external;

    function transferTokenOrSwap(
        uint256 pairIndex,
        address token,
        address to,
        uint256 amount
    ) external;

    function getLpPnl(
        uint256 _pairIndex,
        bool lpIsLong,
        uint amount,
        uint256 _price
    ) external view returns (int256);

    function lpProfit(
        uint pairIndex,
        address token,
        uint256 price
    ) external view returns (int256);

    function increaseReserveAmount(
        uint256 _pairToken,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) external;

    function decreaseReserveAmount(
        uint256 _pairToken,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) external;

    function updateAveragePrice(uint256 _pairIndex, uint256 _averagePrice) external;

    function setLPStableProfit(uint256 _pairIndex, int256 _profit) external;

    function givebackTradingFee(
        uint256 pairIndex,
        uint256 amount
    ) external;

    function getAvailableLiquidity(uint256 pairIndex, uint256 price) external view returns(int256 v, int256 u, int256 e);

    function addLiquidity(
        address recipient,
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount,
        bytes calldata data
    ) external returns (uint256 mintAmount, address slipToken, uint256 slipAmount);

    function removeLiquidity(
        address payable _receiver,
        uint256 _pairIndex,
        uint256 _amount,
        bool useETH,
        bytes calldata data
    )
        external
        returns (uint256 receivedIndexAmount, uint256 receivedStableAmount, uint256 feeAmount);

    function claimFee(address token, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPoolToken {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IPoolTokenFactory {
    function createPoolToken(address indexToken, address stableToken) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPoolView {

    event UpdatePool(address sender, address oldAddress, address newAddress);

    event UpdatePositionManager(address sender, address oldAddress, address newAddress);

    function getMintLpAmount(
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount,
        uint256 price
    ) external view returns (
            uint256 mintAmount,
            address slipToken,
            uint256 slipAmount,
            uint256 indexFeeAmount,
            uint256 stableFeeAmount,
            uint256 afterFeeIndexAmount,
            uint256 afterFeeStableAmount
        );

    function getDepositAmount(
        uint256 _pairIndex,
        uint256 _lpAmount,
        uint256 price
    ) external view returns (uint256 depositIndexAmount, uint256 depositStableAmount);

    function getReceivedAmount(
        uint256 _pairIndex,
        uint256 _lpAmount,
        uint256 price
    ) external view returns (
        uint256 receiveIndexTokenAmount,
        uint256 receiveStableTokenAmount,
        uint256 feeAmount,
        uint256 feeIndexTokenAmount,
        uint256 feeStableTokenAmount
    );

    function lpFairPrice(uint256 _pairIndex, uint256 price) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import '../libraries/Position.sol';
import "./IFeeCollector.sol";

enum PositionStatus {
    Balance,
    NetLong,
    NetShort
}

interface IPositionManager {
    event UpdateFundingInterval(uint256 oldInterval, uint256 newInterval);

    event UpdatePosition(
        address account,
        bytes32 positionKey,
        uint256 pairIndex,
        uint256 orderId,
        bool isLong,
        uint256 beforCollateral,
        uint256 afterCollateral,
        uint256 price,
        uint256 beforPositionAmount,
        uint256 afterPositionAmount,
        uint256 averagePrice,
        int256 fundFeeTracker,
        int256 pnl
    );

    event UpdatedExecutionLogic(address sender, address oldAddress, address newAddress);

    event UpdatedLiquidationLogic(address sender, address oldAddress, address newAddress);

    event UpdateRouterAddress(address sender, address oldAddress, address newAddress);

    event UpdateFundingRate(uint256 pairIndex, uint price, int256 fundingRate, uint256 lastFundingTime);

    event TakeFundingFeeAddTraderFeeV2(
        address account,
        uint256 pairIndex,
        uint256 orderId,
        uint256 sizeDelta,
        int256 fundingFee,
        uint256 regularTradingFee,
        int256 vipTradingFee,
        uint256 returnAmount,
        int256 lpTradingFee
    );

    event AdjustCollateral(
        address account,
        uint256 pairIndex,
        bool isLong,
        bytes32 positionKey,
        uint256 collateralBefore,
        uint256 collateralAfter
    );

    function getExposedPositions(uint256 pairIndex) external view returns (int256);

    function longTracker(uint256 pairIndex) external view returns (uint256);

    function shortTracker(uint256 pairIndex) external view returns (uint256);

    function getTradingFee(
        uint256 _pairIndex,
        bool _isLong,
        bool _isIncrease,
        uint256 _sizeAmount,
        uint256 price
    ) external view returns (uint256 tradingFee);

    function getFundingFee(
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) external view returns (int256 fundingFee);

    function getCurrentFundingRate(uint256 _pairIndex) external view returns (int256);

    function getNextFundingRate(uint256 _pairIndex, uint256 price) external view returns (int256);

    function getNextFundingRateUpdateTime(uint256 _pairIndex) external view returns (uint256);

    function needADL(
        uint256 pairIndex,
        bool isLong,
        uint256 executionSize,
        uint256 executionPrice
    ) external view returns (bool needADL, uint256 needADLAmount);

    function needLiquidation(
        bytes32 positionKey,
        uint256 price
    ) external view returns (bool);

    function getPosition(
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) external view returns (Position.Info memory);

    function getPositionByKey(bytes32 key) external view returns (Position.Info memory);

    function getPositionKey(address _account, uint256 _pairIndex, bool _isLong) external pure returns (bytes32);

    function increasePosition(
        uint256 _pairIndex,
        uint256 orderId,
        address _account,
        address _keeper,
        uint256 _sizeAmount,
        bool _isLong,
        int256 _collateral,
        IFeeCollector.TradingFeeTier memory tradingFeeTier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner,
        uint256 _price
    ) external returns (uint256 tradingFee, int256 fundingFee);

    function decreasePosition(
        uint256 _pairIndex,
        uint256 orderId,
        address _account,
        address _keeper,
        uint256 _sizeAmount,
        bool _isLong,
        int256 _collateral,
        IFeeCollector.TradingFeeTier memory tradingFeeTier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner,
        uint256 _price,
        bool useRiskReserve
    ) external returns (uint256 tradingFee, int256 fundingFee, int256 pnl);

    function adjustCollateral(uint256 pairIndex, address account, bool isLong, int256 collateral) external;

    function updateFundingRate(uint256 _pairIndex) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceFeed {

    event PriceAgeUpdated(uint256 oldAge, uint256 newAge);

    function getPrice(address token) external view returns (uint256);

    function getPriceSafely(address token) external view returns (uint256);

    function decimals() external pure returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOraclePriceFeed.sol";

interface IPythOraclePriceFeed is IOraclePriceFeed {

    event TokenPriceIdUpdated(
        address token,
        bytes32 priceId
    );

    event PythPriceUpdated(address token, uint256 price, uint64 publishTime);

    event PythAddressUpdated(address oldAddress, address newAddress);

    event UpdatedExecutorAddress(address sender, address oldAddress, address newAddress);

    event UnneededPricePublishWarn();

    function updatePrice(
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    ) external payable;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IRoleManager {
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function isAdmin(address) external view returns (bool);

    function isPoolAdmin(address poolAdmin) external view returns (bool);

    function isOperator(address operator) external view returns (bool);

    function isTreasurer(address treasurer) external view returns (bool);

    function isKeeper(address) external view returns (bool);

    function isBlackList(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPool.sol";

interface ISpotSwap {
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external ;

    function getSwapData(
        IPool.Pair memory pair,
        address _tokenOut,
        uint256 _expectAmountOut
    ) external view returns (address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISwapCallback {
    function swapCallback(
        address indexToken,
        address stableToken,
        uint256 indexAmount,
        uint256 stableAmount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;
pragma abicoder v2;



/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniSwapV3Router  {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";

library AMMUtils {
    function getReserve(
        uint256 k,
        uint256 price,
        uint256 pricePrecision
    ) internal pure returns (uint256 reserveA, uint256 reserveB) {
        require(price > 0, "Invalid price");
        require(k > 0, "Invalid k");

        reserveA = Math.sqrt(Math.mulDiv(k, pricePrecision, price));
        reserveB = k / reserveA;
        return (reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (amountIn == 0) {
            return 0;
        }

        require(reserveIn > 0 && reserveOut > 0, "Invalid reserve");
        amountOut = Math.mulDiv(amountIn, reserveOut, reserveIn + amountIn);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library AmountMath {
    using Math for uint256;
    using SafeMath for uint256;
    uint256 public constant PRICE_PRECISION = 1e30;

    function getStableDelta(uint256 amount, uint256 price) internal pure returns (uint256) {
        return Math.mulDiv(amount, price, PRICE_PRECISION);
    }

    function getIndexAmount(uint256 delta, uint256 price) internal pure returns (uint256) {
        return Math.mulDiv(delta, PRICE_PRECISION, price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library Int256Utils {
    using Strings for uint256;

    function abs(int256 a) internal pure returns (uint256) {
        return a >= 0 ? uint256(a) : uint256(-a);
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    function safeConvertToInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "Value too large to fit in int256.");
        return int256(value);
    }

    function toString(int256 amount) internal pure returns (string memory) {
        return string.concat(amount >= 0 ? '' : '-', abs(amount).toString());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import '../libraries/PrecisionUtils.sol';
import '../libraries/Int256Utils.sol';
import '../libraries/TradingTypes.sol';
import '../libraries/PositionKey.sol';
import "../interfaces/IPool.sol";
import "../helpers/TokenHelper.sol";

library Position {
    using Int256Utils for int256;
    using Math for uint256;
    using PrecisionUtils for uint256;

    struct Info {
        address account;
        uint256 pairIndex;
        bool isLong;
        uint256 collateral;
        uint256 positionAmount;
        uint256 averagePrice;
        int256 fundingFeeTracker;
    }

    function get(
        mapping(bytes32 => Info) storage self,
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) internal view returns (Position.Info storage position) {
        position = self[PositionKey.getPositionKey(_account, _pairIndex, _isLong)];
    }

    function getPositionByKey(
        mapping(bytes32 => Info) storage self,
        bytes32 key
    ) internal view returns (Position.Info storage position) {
        position = self[key];
    }

    function init(Info storage self, uint256 pairIndex, address account, bool isLong, uint256 oraclePrice) internal {
        self.pairIndex = pairIndex;
        self.account = account;
        self.isLong = isLong;
        self.averagePrice = oraclePrice;
    }

    function getUnrealizedPnl(
        Info memory self,
        IPool.Pair memory pair,
        uint256 _sizeAmount,
        uint256 price
    ) internal view returns (int256 pnl) {
        if (price == self.averagePrice || self.averagePrice == 0 || _sizeAmount == 0) {
            return 0;
        }

        if (self.isLong) {
            if (price > self.averagePrice) {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    int256(_sizeAmount),
                    price - self.averagePrice
                );
            } else {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    -int256(_sizeAmount),
                    self.averagePrice - price
                );
            }
        } else {
            if (self.averagePrice > price) {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    int256(_sizeAmount),
                    self.averagePrice - price
                );
            } else {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    -int256(_sizeAmount),
                    price - self.averagePrice
                );
            }
        }

        return pnl;
    }

    function validLeverage(
        Info memory self,
        IPool.Pair memory pair,
        uint256 price,
        int256 _collateral,
        uint256 _sizeAmount,
        bool _increase,
        uint256 maxLeverage,
        uint256 maxPositionAmount,
        bool simpleVerify,
        int256 fundingFee
    ) internal view returns (uint256, uint256) {
        // only increase collateral
        if (_sizeAmount == 0 && _collateral >= 0) {
            return (self.positionAmount, self.collateral);
        }

        uint256 afterPosition;
        if (_increase) {
            afterPosition = self.positionAmount + _sizeAmount;
        } else {
            afterPosition = self.positionAmount >= _sizeAmount ? self.positionAmount - _sizeAmount : 0;
        }

        if (_increase && afterPosition > maxPositionAmount) {
            revert("exceeds max position");
        }

        int256 availableCollateral = int256(self.collateral) + fundingFee;

        // pnl
        if (!simpleVerify) {
            int256 pnl = getUnrealizedPnl(self, pair, self.positionAmount, price);
            if (!_increase && _sizeAmount > 0 && _sizeAmount < self.positionAmount) {
                if (pnl >= 0) {
                    availableCollateral += getUnrealizedPnl(self, pair, self.positionAmount - _sizeAmount, price);
                } else {
//                    availableCollateral += getUnrealizedPnl(self, pair, _sizeAmount, price);
                    availableCollateral += pnl;
                }
            } else {
                availableCollateral += pnl;
            }
        }

        // adjust collateral
        if (_collateral != 0) {
            availableCollateral += _collateral;
        }
        require(simpleVerify || availableCollateral >= 0, 'collateral not enough');

        if (!simpleVerify && ((_increase && _sizeAmount > 0) || _collateral < 0)) {
            uint256 collateralDec = uint256(IERC20Metadata(pair.stableToken).decimals());
            uint256 tokenDec = uint256(IERC20Metadata(pair.indexToken).decimals());

            uint256 tokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - tokenDec);
            uint256 collateralWad = 10 ** (PrecisionUtils.maxTokenDecimals() - collateralDec);

            uint256 afterPositionD = afterPosition * tokenWad;
            uint256 availableD = (availableCollateral.abs() * maxLeverage * collateralWad).divPrice(price);
            require(afterPositionD <= availableD, 'exceeds max leverage');
        }

        return (afterPosition, availableCollateral.abs());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PositionKey {
    function getPositionKey(address account, uint256 pairIndex, bool isLong) internal pure returns (bytes32) {
        require(pairIndex < 2 ** (96 - 32), "ptl");
        return bytes32(
            uint256(uint160(account)) << 96 | pairIndex << 32 | (isLong ? 1 : 0)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';

library PrecisionUtils {
    uint256 public constant PERCENTAGE = 1e8;
    uint256 public constant PRICE_PRECISION = 1e30;
    uint256 public constant MAX_TOKEN_DECIMALS = 18;

    function mulPrice(uint256 amount, uint256 price) internal pure returns (uint256) {
        return Math.mulDiv(amount, price, PRICE_PRECISION);
    }

    function divPrice(uint256 delta, uint256 price) internal pure returns (uint256) {
        return Math.mulDiv(delta, PRICE_PRECISION, price);
    }

    function calculatePrice(uint256 delta, uint256 amount) internal pure returns (uint256) {
        return Math.mulDiv(delta, PRICE_PRECISION, amount);
    }

    function mulPercentage(uint256 amount, uint256 _percentage) internal pure returns (uint256) {
        return Math.mulDiv(amount, _percentage, PERCENTAGE);
    }

    function divPercentage(uint256 amount, uint256 _percentage) internal pure returns (uint256) {
        return Math.mulDiv(amount, PERCENTAGE, _percentage);
    }

    function calculatePercentage(uint256 amount0, uint256 amount1) internal pure returns (uint256) {
        return Math.mulDiv(amount0, PERCENTAGE, amount1);
    }

    function percentage() internal pure returns (uint256) {
        return PERCENTAGE;
    }

    function fundingRatePrecision() internal pure returns (uint256) {
        return PERCENTAGE;
    }

    function pricePrecision() internal pure returns (uint256) {
        return PRICE_PRECISION;
    }

    function maxTokenDecimals() internal pure returns (uint256) {
        return MAX_TOKEN_DECIMALS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TradingTypes {
    enum TradeType {
        MARKET,
        LIMIT,
        TP,
        SL
    }

    enum NetworkFeePaymentType {
        ETH,
        COLLATERAL
    }

    struct CreateOrderRequest {
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT 2: TP 3: SL
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 openPrice; // 1e30, price
        bool isLong; // long or short
        int256 sizeAmount; // size
        uint256 maxSlippage;
        InnerPaymentType paymentType;
        uint256 networkFeeAmount;
        bytes data;
    }

    struct OrderWithTpSl {
        uint256 tpPrice; // 1e30, tp price
        uint128 tp; // tp size
        uint256 slPrice; // 1e30, sl price
        uint128 sl; // sl size
    }

    struct IncreasePositionRequest {
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT 2: TP 3: SL
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 openPrice; // 1e30, price
        bool isLong; // long or short
        uint256 sizeAmount; // size
        uint256 maxSlippage;
        NetworkFeePaymentType paymentType;
        uint256 networkFeeAmount;
    }

    struct IncreasePositionWithTpSlRequest {
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT 2: TP 3: SL
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 openPrice; // 1e30, price
        bool isLong; // long or short
        uint128 sizeAmount; // size
        uint256 tpPrice; // 1e30, tp price
        uint128 tp; // tp size
        uint256 slPrice; // 1e30, sl price
        uint128 sl; // sl size
        uint256 maxSlippage;
        NetworkFeePaymentType paymentType; // 1: eth 2: collateral
        uint256 networkFeeAmount;
        uint256 tpNetworkFeeAmount;
        uint256 slNetworkFeeAmount;
    }

    struct DecreasePositionRequest {
        address account;
        uint256 pairIndex;
        TradeType tradeType;
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 triggerPrice; // 1e30, price
        uint256 sizeAmount; // size
        bool isLong;
        uint256 maxSlippage;
        NetworkFeePaymentType paymentType;
        uint256 networkFeeAmount;
    }

    struct CreateTpSlRequest {
        address account;
        uint256 pairIndex; // pair index
        bool isLong;
        uint256 tpPrice; // Stop profit price 1e30
        uint128 tp; // The number of profit stops
        uint256 slPrice; // Stop price 1e30
        uint128 sl; // Stop loss quantity
        NetworkFeePaymentType paymentType;
        uint256 tpNetworkFeeAmount;
        uint256 slNetworkFeeAmount;
    }

    struct IncreasePositionOrder {
        uint256 orderId;
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT
        int256 collateral; // 1e18 Margin amount
        uint256 openPrice; // 1e30 Market acceptable price/Limit opening price
        bool isLong; // Long/short
        uint256 sizeAmount; // Number of positions
        uint256 executedSize;
        uint256 maxSlippage;
        uint256 blockTime;
    }

    struct DecreasePositionOrder {
        uint256 orderId;
        address account;
        uint256 pairIndex;
        TradeType tradeType;
        int256 collateral; // 1e18 Margin amount
        uint256 triggerPrice; // Limit trigger price
        uint256 sizeAmount; // Number of customs documents
        uint256 executedSize;
        uint256 maxSlippage;
        bool isLong;
        bool abovePrice; // Above or below the trigger price
        // market：long: true,  short: false
        //  limit：long: false, short: true
        //     tp：long: false, short: true
        //     sl：long: true,  short: false
        uint256 blockTime;
        bool needADL;
    }

    struct OrderNetworkFee {
        InnerPaymentType paymentType;
        uint256 networkFeeAmount;
    }

    enum InnerPaymentType {
        NONE,
        ETH,
        COLLATERAL
    }

    function convertPaymentType(
        NetworkFeePaymentType paymentType
    ) internal pure returns (InnerPaymentType) {
        if (paymentType == NetworkFeePaymentType.ETH) {
            return InnerPaymentType.ETH;
        } else if (paymentType == NetworkFeePaymentType.COLLATERAL) {
            return InnerPaymentType.COLLATERAL;
        } else {
            revert("Invalid payment type");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";

contract Upgradeable is Initializable, UUPSUpgradeable {
    IAddressesProvider public ADDRESS_PROVIDER;

    modifier onlyAdmin() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isAdmin(msg.sender), "onlyAdmin");
        _;
    }

    modifier onlyPoolAdmin() {
        require(
            IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender),
            "onlyPoolAdmin"
        );
        _;
    }

    function _authorizeUpgrade(address) internal virtual override {
        require(msg.sender == ADDRESS_PROVIDER.timelock(), "Unauthorized access");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IPositionManager.sol";
import "../interfaces/IUniSwapV3Router.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IPoolToken.sol";
import "../interfaces/IPoolTokenFactory.sol";
import "../interfaces/ISwapCallback.sol";
import "../interfaces/IPythOraclePriceFeed.sol";
import "../interfaces/ISpotSwap.sol";
import "../interfaces/ILiquidityCallback.sol";
import "../interfaces/IWETH.sol";
import "../libraries/AmountMath.sol";
import "../libraries/Upgradeable.sol";
import "../libraries/Int256Utils.sol";
import "../libraries/AMMUtils.sol";
import "../libraries/PrecisionUtils.sol";
import "../token/interfaces/IBaseToken.sol";
import "../helpers/ValidationHelper.sol";
import "../helpers/TokenHelper.sol";
import "../interfaces/IPoolView.sol";

contract Pool is IPool, Upgradeable {
    using PrecisionUtils for uint256;
    using SafeERC20 for IERC20;
    using Int256Utils for int256;
    using Math for uint256;
    using SafeMath for uint256;

    IPoolTokenFactory public poolTokenFactory;
    IPoolView public poolView;

    address public riskReserve;
    address public feeCollector;

    mapping(uint256 => TradingConfig) public tradingConfigs;
    mapping(uint256 => TradingFeeConfig) public tradingFeeConfigs;

    mapping(address => mapping(address => uint256)) public override getPairIndex;

    uint256 public pairsIndex;
    mapping(uint256 => Pair) public pairs;
    mapping(uint256 => Vault) public vaults;
    address public positionManager;
    address public orderManager;
    address public router;

    mapping(address => uint256) public feeTokenAmounts;
    mapping(address => bool) public isStableToken;
    address public spotSwap;

    function initialize(
        IAddressesProvider addressProvider,
        IPoolTokenFactory _poolTokenFactory
    ) public initializer {
        ADDRESS_PROVIDER = addressProvider;
        poolTokenFactory = _poolTokenFactory;
        pairsIndex = 1;
    }

    modifier transferAllowed() {
        require(
            positionManager == msg.sender ||
                orderManager == msg.sender ||
                riskReserve == msg.sender ||
                feeCollector == msg.sender,
            "pd"
        );
        _;
    }

    receive() external payable {
        require(msg.sender == ADDRESS_PROVIDER.WETH() || msg.sender == orderManager, "nw");
    }

    modifier onlyPositionManager() {
        require(positionManager == msg.sender, "opm");
        _;
    }

    modifier onlyRouter() {
        require(router == msg.sender, "or");
        _;
    }

    modifier onlyPositionManagerOrFeeCollector() {
        require(
            positionManager == msg.sender || msg.sender == feeCollector,
            "opmof"
        );
        _;
    }

    modifier onlyFeeCollector() {
        require(msg.sender == feeCollector, "only fc");
        _;
    }

    modifier onlyTreasury() {
        require(
            IRoleManager(ADDRESS_PROVIDER.roleManager()).isTreasurer(msg.sender),
            "ot"
        );
        _;
    }

    function _unwrapWETH(uint256 amount, address payable to) private {
        IWETH(ADDRESS_PROVIDER.WETH()).withdraw(amount);
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "err-eth");
    }

    function setPoolView(address _poolView) external onlyPoolAdmin {
        address oldAddress = address(poolView);
        poolView = IPoolView(_poolView);
        emit UpdatePoolView(msg.sender, oldAddress, _poolView);
    }

    function setSpotSwap(address _spotSwap) external onlyPoolAdmin {
        address oldAddress = spotSwap;
        spotSwap = _spotSwap;
        emit UpdateSpotSwap(msg.sender, oldAddress, _spotSwap);
    }

    function setRiskReserve(address _riskReserve) external onlyPoolAdmin {
        address oldAddress = riskReserve;
        riskReserve = _riskReserve;
        emit UpdateRiskReserve(msg.sender, oldAddress, _riskReserve);
    }

    function setFeeCollector(address _feeCollector) external onlyPoolAdmin {
        address oldAddress = feeCollector;
        feeCollector = _feeCollector;
        emit UpdateFeeCollector(msg.sender, oldAddress, _feeCollector);
    }

    function setPositionManager(address _positionManager) external onlyPoolAdmin {
        address oldAddress = positionManager;
        positionManager = _positionManager;
        emit UpdatePositionManager(msg.sender, oldAddress, _positionManager);
    }

    function setOrderManager(address _orderManager) external onlyPoolAdmin {
        address oldAddress = orderManager;
        orderManager = _orderManager;
        emit UpdateOrderManager(msg.sender, oldAddress, _orderManager);
    }

    function setRouter(address _router) external onlyPoolAdmin {
        address oldAddress = router;
        router = _router;
        emit UpdateRouter(msg.sender, oldAddress, _router);
    }

    function addStableToken(address _token) external onlyPoolAdmin {
        isStableToken[_token] = true;
        emit AddStableToken(msg.sender, _token);
    }

    function removeStableToken(address _token) external onlyPoolAdmin {
        delete isStableToken[_token];
        emit RemoveStableToken(msg.sender, _token);
    }

    function addPair(address _indexToken, address _stableToken) external onlyPoolAdmin {
        require(_indexToken != address(0) && _stableToken != address(0), "!0");
        require(isStableToken[_stableToken], "!st");
        require(getPairIndex[_indexToken][_stableToken] == 0, "ex");
        require(IERC20Metadata(_indexToken).decimals() <= 18 && IERC20Metadata(_stableToken).decimals() <= 18, "!de");

        address pairToken = poolTokenFactory.createPoolToken(_indexToken, _stableToken);

        getPairIndex[_indexToken][_stableToken] = pairsIndex;
        getPairIndex[_stableToken][_indexToken] = pairsIndex;

        Pair storage pair = pairs[pairsIndex];
        pair.pairIndex = pairsIndex;
        pair.indexToken = _indexToken;

        pair.stableToken = _stableToken;
        pair.pairToken = pairToken;

        emit PairAdded(_indexToken, _stableToken, pairToken, pairsIndex++);
    }

    function updatePair(uint256 _pairIndex, Pair calldata _pair) external onlyPoolAdmin {
        Pair storage pair = pairs[_pairIndex];
        require(
            pair.indexToken != address(0) && pair.stableToken != address(0),
            "nex"
        );
        require(
            _pair.expectIndexTokenP <= PrecisionUtils.percentage() &&
                _pair.maxUnbalancedP <= PrecisionUtils.percentage() &&
                _pair.unbalancedDiscountRate <= PrecisionUtils.percentage() &&
                _pair.addLpFeeP <= PrecisionUtils.percentage() &&
                _pair.removeLpFeeP <= PrecisionUtils.percentage(),
            "ex"
        );

        pair.enable = _pair.enable;
        pair.kOfSwap = _pair.kOfSwap;
        pair.expectIndexTokenP = _pair.expectIndexTokenP;
        pair.maxUnbalancedP = _pair.maxUnbalancedP;
        pair.unbalancedDiscountRate = _pair.unbalancedDiscountRate;
        pair.addLpFeeP = _pair.addLpFeeP;
        pair.removeLpFeeP = _pair.removeLpFeeP;
    }

    function updateTradingConfig(
        uint256 _pairIndex,
        TradingConfig calldata _tradingConfig
    ) external onlyPoolAdmin {
        Pair storage pair = pairs[_pairIndex];
        require(
            pair.indexToken != address(0) && pair.stableToken != address(0),
            "pnt"
        );
        require(
            _tradingConfig.maintainMarginRate <= PrecisionUtils.percentage() &&
                _tradingConfig.priceSlipP <= PrecisionUtils.percentage() &&
                _tradingConfig.maxPriceDeviationP <= PrecisionUtils.percentage(),
            "ex"
        );
        tradingConfigs[_pairIndex] = _tradingConfig;
    }

    function updateTradingFeeConfig(
        uint256 _pairIndex,
        TradingFeeConfig calldata _tradingFeeConfig
    ) external onlyPoolAdmin {
        Pair storage pair = pairs[_pairIndex];
        require(
            pair.indexToken != address(0) && pair.stableToken != address(0),
            "pne"
        );
        require(
            _tradingFeeConfig.lpFeeDistributeP +
                _tradingFeeConfig.keeperFeeDistributeP +
                _tradingFeeConfig.stakingFeeDistributeP +
                _tradingFeeConfig.treasuryFeeDistributeP +
                _tradingFeeConfig.reservedFeeDistributeP +
                _tradingFeeConfig.ecoFundFeeDistributeP <=
                PrecisionUtils.percentage(),
            "ex"
        );
        tradingFeeConfigs[_pairIndex] = _tradingFeeConfig;
    }

    function _increaseTotalAmount(
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) internal {
        Vault storage vault = vaults[_pairIndex];
        vault.indexTotalAmount = vault.indexTotalAmount + _indexAmount;
        vault.stableTotalAmount = vault.stableTotalAmount + _stableAmount;
        emit UpdateTotalAmount(
            _pairIndex,
            int256(_indexAmount),
            int256(_stableAmount),
            vault.indexTotalAmount,
            vault.stableTotalAmount
        );
    }

    function _decreaseTotalAmount(
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) internal {
        Vault storage vault = vaults[_pairIndex];
        require(vault.indexTotalAmount >= _indexAmount, "ix");
        require(vault.stableTotalAmount >= _stableAmount, "ix");

        vault.indexTotalAmount = vault.indexTotalAmount - _indexAmount;
        vault.stableTotalAmount = vault.stableTotalAmount - _stableAmount;
        emit UpdateTotalAmount(
            _pairIndex,
            -int256(_indexAmount),
            -int256(_stableAmount),
            vault.indexTotalAmount,
            vault.stableTotalAmount
        );
    }

    function increaseReserveAmount(
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) external onlyPositionManager {
        Vault storage vault = vaults[_pairIndex];
        vault.indexReservedAmount = vault.indexReservedAmount + _indexAmount;
        vault.stableReservedAmount = vault.stableReservedAmount + _stableAmount;
        emit UpdateReserveAmount(
            _pairIndex,
            int256(_indexAmount),
            int256(_stableAmount),
            vault.indexReservedAmount,
            vault.stableReservedAmount
        );
    }

    function decreaseReserveAmount(
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) external onlyPositionManager {
        Vault storage vault = vaults[_pairIndex];
        require(vault.indexReservedAmount >= _indexAmount, "ex");
        require(vault.stableReservedAmount >= _stableAmount, "ex");

        vault.indexReservedAmount = vault.indexReservedAmount - _indexAmount;
        vault.stableReservedAmount = vault.stableReservedAmount - _stableAmount;
        emit UpdateReserveAmount(
            _pairIndex,
            -int256(_indexAmount),
            -int256(_stableAmount),
            vault.indexReservedAmount,
            vault.stableReservedAmount
        );
    }

    function updateAveragePrice(
        uint256 _pairIndex,
        uint256 _averagePrice
    ) external onlyPositionManager {
        vaults[_pairIndex].averagePrice = _averagePrice;
        emit UpdateAveragePrice(_pairIndex, _averagePrice);
    }

    function setLPStableProfit(
        uint256 _pairIndex,
        int256 _profit
    ) external onlyPositionManagerOrFeeCollector {
        Vault storage vault = vaults[_pairIndex];
        Pair memory pair = pairs[_pairIndex];
        if (_profit > 0) {
            vault.stableTotalAmount += _profit.abs();
        } else {
            if (vault.stableTotalAmount < _profit.abs()) {
                _swapInUni(_pairIndex, pair.stableToken, _profit.abs());
            }
            vault.stableTotalAmount -= _profit.abs();
        }

        emit UpdateLPProfit(_pairIndex, pair.stableToken, _profit, vault.stableTotalAmount);
    }

    function givebackTradingFee(
        uint256 pairIndex,
        uint256 amount
    ) external onlyFeeCollector {
        Vault storage vault = vaults[pairIndex];
        require(vault.stableTotalAmount >= amount, "insufficient liquidity");

        vault.stableTotalAmount -= amount;

        Pair memory pair = pairs[pairIndex];
        emit GivebackTradingFee(pairIndex, pair.stableToken, amount);
    }

    function getAvailableLiquidity(uint256 pairIndex, uint256 price) external view returns(int256 v, int256 u, int256 e) {
        Vault memory vault = getVault(pairIndex);
        Pair memory pair = getPair(pairIndex);

        v = TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(vault.indexTotalAmount), price)
            + int256(vault.stableReservedAmount)
            - TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(vault.indexReservedAmount), price);
        u = int256(vault.stableTotalAmount)
            + TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(vault.indexReservedAmount), price)
            - int256(vault.stableReservedAmount);
        e = v - u;
    }

    function addLiquidity(
        address recipient,
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount,
        bytes calldata data
    ) external onlyRouter returns (uint256 mintAmount, address slipToken, uint256 slipAmount) {
        ValidationHelper.validateAccountBlacklist(ADDRESS_PROVIDER, recipient);

        Pair memory pair = pairs[_pairIndex];
        require(pair.enable, "disabled");

        return _addLiquidity(recipient, _pairIndex, _indexAmount, _stableAmount, data);
    }

    function removeLiquidity(
        address payable _receiver,
        uint256 _pairIndex,
        uint256 _amount,
        bool useETH,
        bytes calldata data
    ) external onlyRouter returns (uint256 receivedIndexAmount, uint256 receivedStableAmount, uint256 feeAmount) {
        ValidationHelper.validateAccountBlacklist(ADDRESS_PROVIDER, _receiver);

        Pair memory pair = pairs[_pairIndex];
        require(pair.enable, "disabled");

        (receivedIndexAmount, receivedStableAmount, feeAmount) = _removeLiquidity(
            _receiver,
            _pairIndex,
            _amount,
            useETH,
            data
        );

        return (receivedIndexAmount, receivedStableAmount, feeAmount);
    }

    function _transferToken(
        address indexToken,
        address stableToken,
        uint256 indexAmount,
        uint256 stableAmount,
        bytes calldata data
    ) internal {
        uint256 balanceIndexBefore;
        uint256 balanceStableBefore;
        if (indexAmount > 0) balanceIndexBefore = IERC20(indexToken).balanceOf(address(this));
        if (stableAmount > 0) balanceStableBefore = IERC20(stableToken).balanceOf(address(this));
        ILiquidityCallback(msg.sender).addLiquidityCallback(
            indexToken,
            stableToken,
            indexAmount,
            stableAmount,
            data
        );

        if (indexAmount > 0)
            require(
                balanceIndexBefore.add(indexAmount) <= IERC20(indexToken).balanceOf(address(this)),
                "ti"
            );
        if (stableAmount > 0) {
            require(
                balanceStableBefore.add(stableAmount) <=
                    IERC20(stableToken).balanceOf(address(this)),
                "ts"
            );
        }
    }

    function _swapInUni(uint256 _pairIndex, address _tokenOut, uint256 _expectAmountOut) private {
        Pair memory pair = pairs[_pairIndex];
        (
            address tokenIn,
            address tokenOut,
            uint256 amountInMaximum,
            uint256 expectAmountOut
        ) = ISpotSwap(spotSwap).getSwapData(pair, _tokenOut, _expectAmountOut);

        if (IERC20(tokenIn).allowance(address(this), spotSwap) < amountInMaximum) {
            IERC20(tokenIn).safeApprove(spotSwap, type(uint256).max);
        }
        ISpotSwap(spotSwap).swap(tokenIn, tokenOut, amountInMaximum, expectAmountOut);
    }

    function _getStableTotalAmount(
        IPool.Pair memory pair,
        IPool.Vault memory vault,
        uint256 price
    ) internal view returns (uint256) {
        int256 profit = lpProfit(pair.pairIndex, pair.stableToken, price);
        if (profit < 0) {
            return vault.stableTotalAmount > profit.abs() ? vault.stableTotalAmount.sub(profit.abs()) : 0;
        } else {
            return vault.stableTotalAmount.add(profit.abs());
        }
    }

    function _getIndexTotalAmount(
        IPool.Pair memory pair,
        IPool.Vault memory vault,
        uint256 price
    ) internal view returns (uint256) {
        int256 profit = lpProfit(pair.pairIndex, pair.indexToken, price);
        if (profit < 0) {
            return vault.indexTotalAmount > profit.abs() ? vault.indexTotalAmount.sub(profit.abs()) : 0;
        } else {
            return vault.indexTotalAmount.add(profit.abs());
        }
    }

    function _addLiquidity(
        address recipient,
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount,
        bytes calldata data
    ) private returns (uint256 mintAmount, address slipToken, uint256 slipAmount) {
        require(_indexAmount > 0 || _stableAmount > 0, "ia");

        IPool.Pair memory pair = getPair(_pairIndex);
        require(pair.pairToken != address(0), "ip");

        _transferToken(pair.indexToken, pair.stableToken, _indexAmount, _stableAmount, data);

        uint256 price = IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).getPriceSafely(pair.indexToken);
        uint256 lpPrice = poolView.lpFairPrice(_pairIndex, price);

        uint256 indexFeeAmount;
        uint256 stableFeeAmount;
        uint256 afterFeeIndexAmount;
        uint256 afterFeeStableAmount;
        (
            mintAmount,
            slipToken,
            slipAmount,
            indexFeeAmount,
            stableFeeAmount,
            afterFeeIndexAmount,
            afterFeeStableAmount
        ) = poolView.getMintLpAmount(_pairIndex, _indexAmount, _stableAmount, price);

        feeTokenAmounts[pair.indexToken] += indexFeeAmount;
        feeTokenAmounts[pair.stableToken] += stableFeeAmount;

        if (slipToken == pair.indexToken) {
            afterFeeIndexAmount += slipAmount;
        } else if (slipToken == pair.stableToken) {
            afterFeeStableAmount += slipAmount;
        }
        _increaseTotalAmount(_pairIndex, afterFeeIndexAmount, afterFeeStableAmount);

        IBaseToken(pair.pairToken).mint(recipient, mintAmount);

        emit AddLiquidity(
            recipient,
            _pairIndex,
            _indexAmount,
            _stableAmount,
            mintAmount,
            indexFeeAmount,
            stableFeeAmount,
            slipToken,
            slipAmount,
            lpPrice
        );

        return (mintAmount, slipToken, slipAmount);
    }

    function _removeLiquidity(
        address payable _receiver,
        uint256 _pairIndex,
        uint256 _amount,
        bool useETH,
        bytes calldata data
    )
        private
        returns (
            uint256 receiveIndexTokenAmount,
            uint256 receiveStableTokenAmount,
            uint256 feeAmount
        )
    {
        require(_amount > 0, "ia");
        IPool.Pair memory pair = getPair(_pairIndex);
        require(pair.pairToken != address(0), "ip");

        uint256 price = IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).getPriceSafely(pair.indexToken);
        uint256 lpPrice = poolView.lpFairPrice(_pairIndex, price);

        uint256 feeIndexTokenAmount;
        uint256 feeStableTokenAmount;
        (
            receiveIndexTokenAmount,
            receiveStableTokenAmount,
            feeAmount,
            feeIndexTokenAmount,
            feeStableTokenAmount
        ) = poolView.getReceivedAmount(_pairIndex, _amount, price);

        ILiquidityCallback(msg.sender).removeLiquidityCallback(pair.pairToken, _amount, data);
        IPoolToken(pair.pairToken).burn(_amount);

        IPool.Vault memory vault = getVault(_pairIndex);
        uint256 indexTokenDec = IERC20Metadata(pair.indexToken).decimals();
        uint256 stableTokenDec = IERC20Metadata(pair.stableToken).decimals();

        uint256 availableIndexTokenWad;
        if (vault.indexTotalAmount > vault.indexReservedAmount) {
            uint256 availableIndexToken = vault.indexTotalAmount - vault.indexReservedAmount;
            availableIndexTokenWad = availableIndexToken * (10 ** (18 - indexTokenDec));
        }

        uint256 availableStableTokenWad;
        if (vault.stableTotalAmount > vault.stableReservedAmount) {
            uint256 availableStableToken = vault.stableTotalAmount - vault.stableReservedAmount;
            availableStableTokenWad = availableStableToken * (10 ** (18 - stableTokenDec));
        }

        uint256 receiveIndexTokenAmountWad = receiveIndexTokenAmount * (10 ** (18 - indexTokenDec));
        uint256 receiveStableTokenAmountWad = receiveStableTokenAmount * (10 ** (18 - stableTokenDec));

        uint256 totalAvailable = availableIndexTokenWad.mulPrice(price) + availableStableTokenWad;
        uint256 totalReceive = receiveIndexTokenAmountWad.mulPrice(price) + receiveStableTokenAmountWad;
        require(totalReceive <= totalAvailable, "il");

        feeTokenAmounts[pair.indexToken] += feeIndexTokenAmount;
        feeTokenAmounts[pair.stableToken] += feeStableTokenAmount;

        _decreaseTotalAmount(
            _pairIndex,
            receiveIndexTokenAmount + feeIndexTokenAmount,
            receiveStableTokenAmount + feeStableTokenAmount
        );

        if (receiveIndexTokenAmount > 0) {
            if (useETH && pair.indexToken == ADDRESS_PROVIDER.WETH()) {
                _unwrapWETH(receiveIndexTokenAmount, _receiver);
            } else {
                IERC20(pair.indexToken).safeTransfer(_receiver, receiveIndexTokenAmount);
            }
        }

        if (receiveStableTokenAmount > 0) {
            IERC20(pair.stableToken).safeTransfer(_receiver, receiveStableTokenAmount);
        }

        emit RemoveLiquidity(
            _receiver,
            _pairIndex,
            receiveIndexTokenAmount,
            receiveStableTokenAmount,
            _amount,
            feeAmount,
            lpPrice
        );

        return (receiveIndexTokenAmount, receiveStableTokenAmount, feeAmount);
    }

    function claimFee(address token, uint256 amount) external onlyTreasury {
        require(feeTokenAmounts[token] >= amount, "ex");

        feeTokenAmounts[token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);

        emit ClaimedFee(msg.sender, token, amount);
    }

    function transferTokenTo(address token, address to, uint256 amount) external transferAllowed {
        require(IERC20(token).balanceOf(address(this)) > amount, "Insufficient balance");
        IERC20(token).safeTransfer(to, amount);
    }

    function transferEthTo(address to, uint256 amount) external transferAllowed {
        require(address(this).balance > amount, "Insufficient balance");
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "transfer failed");
    }

    function transferTokenOrSwap(
        uint256 pairIndex,
        address token,
        address to,
        uint256 amount
    ) external transferAllowed {
        if (amount == 0) {
            return;
        }
        Pair memory pair = pairs[pairIndex];
        require(token == pair.indexToken || token == pair.stableToken, "bt");

        uint256 bal = IERC20(token).balanceOf(address(this));
        if (bal < amount) {
            _swapInUni(pairIndex, token, amount);
        }
        IERC20(token).safeTransfer(to, amount);
    }

    function getLpPnl(
        uint256 _pairIndex,
        bool lpIsLong,
        uint amount,
        uint256 _price
    ) public view override returns (int256) {
        Vault memory lpVault = getVault(_pairIndex);
        if (lpIsLong) {
            if (_price > lpVault.averagePrice) {
                return int256(amount.mulPrice(_price - lpVault.averagePrice));
            } else {
                return -int256(amount.mulPrice(lpVault.averagePrice - _price));
            }
        } else {
            if (_price < lpVault.averagePrice) {
                return int256(amount.mulPrice(lpVault.averagePrice - _price));
            } else {
                return -int256(amount.mulPrice(_price - lpVault.averagePrice));
            }
        }
    }

    function lpProfit(
        uint pairIndex,
        address token,
        uint256 price
    ) public view override returns (int256) {
        int256 currentExposureAmountChecker = IPositionManager(positionManager).getExposedPositions(pairIndex);
        if (currentExposureAmountChecker == 0) {
            return 0;
        }

        int256 profit = getLpPnl(
            pairIndex,
            currentExposureAmountChecker < 0,
            currentExposureAmountChecker.abs(),
            price
        );

        Pair memory pair = getPair(pairIndex);
        return
            TokenHelper.convertTokenAmountTo(
            pair.indexToken,
            profit,
            IERC20Metadata(token).decimals()
        );
    }

    function getVault(uint256 _pairIndex) public view returns (Vault memory vault) {
        return vaults[_pairIndex];
    }

    function getPair(uint256 _pairIndex) public view override returns (Pair memory) {
        return pairs[_pairIndex];
    }

    function getTradingConfig(
        uint256 _pairIndex
    ) external view override returns (TradingConfig memory) {
        return tradingConfigs[_pairIndex];
    }

    function getTradingFeeConfig(
        uint256 _pairIndex
    ) external view override returns (TradingFeeConfig memory) {
        return tradingFeeConfigs[_pairIndex];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseToken {
    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function setMiner(address account, bool enable) external;
}